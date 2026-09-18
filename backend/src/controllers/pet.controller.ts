import { Response } from 'express';
import { ZodError } from 'zod';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { PetModel, PetRecord, PetInputSchema } from '../models/pet.model.js';
import { AuditLogModel } from '../models/audit_log.model.js';
import { ResponseView } from '../views/response.view.js';
import { containsProhibitedContent } from '../utils/content_filter.js';

/**
 * Valida formato/rango de los campos de mascota presentes en el body.
 * Devuelve `true` y ya respondió 422 si el body es inválido; el caller
 * debe cortar la ejecución en ese caso.
 */
function rejectIfInvalidPetInput(body: Record<string, unknown>, res: Response): boolean {
  try {
    PetInputSchema.parse(body);
  } catch (err) {
    if (err instanceof ZodError) {
      ResponseView.error(res, 'Algunos datos de la mascota no son válidos', 422, err.errors);
      return true;
    }
    ResponseView.internalError(res, err);
    return true;
  }

  const freeTextFields = ['story', 'special_needs'] as const;
  for (const field of freeTextFields) {
    const value = body[field];
    if (typeof value === 'string' && containsProhibitedContent(value)) {
      ResponseView.error(res, 'La descripción de la mascota contiene lenguaje no permitido', 422);
      return true;
    }
  }

  return false;
}

export class PetController {
  /**
   * Obtener lista de mascotas para el deck de Tinder (excluye ya vistas)
   * Soporta filtros opcionales de especie y tipo de publicador (refugio o camada particular)
   */
  static async getFeed(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
      const species = req.query.species as string | undefined;
      const publisherType = req.query.publisher_type as string | undefined;

      const pets = await PetModel.getFeedForAdopter(userId, { limit, species, publisherType });

      ResponseView.success(res, pets, 'Feed de mascotas recuperado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Obtener detalle completo de una mascota
   */
  static async getDetail(req: AuthenticatedRequest, res: Response): Promise<void> {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    if (!id) {
      ResponseView.error(res, 'ID de mascota requerido', 400);
      return;
    }

    try {
      const pet = await PetModel.findById(id);
      if (!pet) {
        ResponseView.notFound(res, 'Mascota no encontrada');
        return;
      }

      ResponseView.success(res, pet, 'Detalle de mascota');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Registrar una nueva mascota en adopción
   * Autorizado para: Refugios ('shelter') y Particulares con camadas / Rescatistas ('individual_rescuer')
   */
  static async create(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const role = req.user?.role;

    if (!userId || (role !== 'shelter' && role !== 'individual_rescuer' && role !== 'admin')) {
      ResponseView.forbidden(
        res,
        'Solo los refugios o particulares/rescatistas registrados pueden publicar mascotas en adopción'
      );
      return;
    }

    const body = req.body;
    if (rejectIfInvalidPetInput(body, res)) return;

    // Validación ética: Protección del destete en cachorros de camadas
    if (body.is_litter && body.age_years < 0.16 && !body.weaning_completed) {
      // 0.16 años aprox. 60 días
      ResponseView.error(
        res,
        'Por bienestar animal, los cachorros de camadas deben haber cumplido al menos 60 días (destete ético) antes de ser entregados en adopción.',
        422
      );
      return;
    }

    try {
      const publisherType = role === 'individual_rescuer' ? 'individual_rescuer' : 'shelter';

      const newPet = await PetModel.create({
        shelter_id: userId,
        publisher_type: publisherType,
        name: body.name,
        species: body.species || 'dog',
        breed: body.breed || 'Mestizo',
        age_years: typeof body.age_years === 'number' ? body.age_years : 1.0,
        gender: body.gender || 'male',
        size: body.size || 'medium',
        energy_level: body.energy_level || 3,

        origin: body.origin || (role === 'individual_rescuer' ? 'home_litter' : 'street_rescue'),
        is_litter: Boolean(body.is_litter),
        birth_date: body.birth_date || null,
        weaning_completed: body.weaning_completed ?? true,

        is_vaccinated: Boolean(body.is_vaccinated),
        vaccines_applied: Array.isArray(body.vaccines_applied) ? body.vaccines_applied : [],
        dewormed_internal: Boolean(body.dewormed_internal),
        dewormed_external: Boolean(body.dewormed_external),
        has_microchip: Boolean(body.has_microchip),
        is_neutered: Boolean(body.is_neutered),
        reproductive_status: body.reproductive_status || (body.is_neutered ? 'neutered' : 'intact'),

        house_trained: body.house_trained ?? true,
        good_with_dogs: body.good_with_dogs ?? true,
        good_with_cats: body.good_with_cats ?? true,
        good_with_kids: body.good_with_kids ?? true,
        requires_yard: Boolean(body.requires_yard),
        storm_anxiety: body.storm_anxiety || 1,
        special_needs: body.special_needs || null,
        story: body.story || 'Sin historia detallada.',

        requires_adoption_contract: body.requires_adoption_contract ?? true,
        requires_home_check: Boolean(body.requires_home_check),
        requires_followup_photos: body.requires_followup_photos ?? true,
        delivery_type: body.delivery_type || 'to_be_agreed',

        photos: Array.isArray(body.photos) ? body.photos : [],
        status: 'available',
        moderation_status: 'approved',
        latitude: typeof body.latitude === 'number' ? body.latitude : null,
        longitude: typeof body.longitude === 'number' ? body.longitude : null,
      });

      ResponseView.success(res, newPet, 'Mascota publicada exitosamente para adopción', 201);
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Obtener inventario del refugio (Disponibles, Pausadas, Adoptadas)
   */
  static async getInventory(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const pets = await PetModel.findByShelterId(userId);
      ResponseView.success(res, pets, 'Inventario de mascotas recuperado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Pausar, reactivar o marcar como adoptada una mascota
   */
  static async updateStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const { status } = req.body;

    if (!userId || !id) {
      ResponseView.error(res, 'ID y usuario requeridos', 400);
      return;
    }

    if (!['available', 'paused', 'in_process', 'adopted'].includes(status)) {
      ResponseView.error(res, 'Estado no válido', 400);
      return;
    }

    try {
      const updated = await PetModel.updateStatus(id, userId, status);
      ResponseView.success(res, updated, 'Estado de la mascota actualizado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Editar los datos de una mascota ya publicada (sólo el propio publicador)
   */
  static async updatePet(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    if (!userId || !id) {
      ResponseView.error(res, 'ID y usuario requeridos', 400);
      return;
    }

    const body = req.body;
    if (rejectIfInvalidPetInput(body, res)) return;

    const editableFields = [
      'name', 'species', 'breed', 'age_years', 'gender', 'size', 'energy_level',
      'is_litter', 'birth_date', 'weaning_completed',
      'is_vaccinated', 'vaccines_applied', 'dewormed_internal', 'dewormed_external',
      'has_microchip', 'is_neutered', 'reproductive_status',
      'house_trained', 'good_with_dogs', 'good_with_cats', 'good_with_kids',
      'requires_yard', 'storm_anxiety', 'special_needs', 'story',
      'requires_adoption_contract', 'requires_home_check', 'requires_followup_photos',
      'delivery_type', 'photos', 'latitude', 'longitude',
    ] as const;

    const patch: Record<string, unknown> = {};
    for (const field of editableFields) {
      if (body[field] !== undefined) {
        patch[field] = body[field];
      }
    }

    if (Object.keys(patch).length === 0) {
      ResponseView.error(res, 'No se enviaron campos para actualizar', 400);
      return;
    }

    try {
      const updated = await PetModel.update(id, userId, patch as never);
      if (!updated) {
        ResponseView.notFound(res, 'Mascota no encontrada o no te pertenece');
        return;
      }
      ResponseView.success(res, updated, 'Mascota actualizada correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Eliminar una publicación. Se bloquea si ya tiene matches, para no borrar
   * historial de postulaciones en curso; en ese caso conviene pausarla.
   */
  static async deletePet(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    if (!userId || !id) {
      ResponseView.error(res, 'ID y usuario requeridos', 400);
      return;
    }

    try {
      const matchCount = await PetModel.countMatches(id);
      if (matchCount > 0) {
        ResponseView.error(
          res,
          'No se puede eliminar: esta mascota ya tiene postulaciones o matches. Podés pausarla en su lugar.',
          409
        );
        return;
      }

      const deleted = await PetModel.delete(id, userId);
      if (!deleted) {
        ResponseView.notFound(res, 'Mascota no encontrada o no te pertenece');
        return;
      }
      ResponseView.success(res, null, 'Mascota eliminada correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Caso Excepcional: Adoptante que debe reubicar a su mascota por mudanza o fuerza mayor
   */
  static async relocatePet(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    const body = req.body;
    if (rejectIfInvalidPetInput(body, res)) return;

    if (!body.relocation_reason || typeof body.relocation_reason !== 'string' || body.relocation_reason.trim().length < 15) {
      ResponseView.error(
        res,
        'Debe detallar un motivo justificado para la reubicación (mínimo 15 caracteres: mudanza, causa de fuerza mayor, etc.).',
        422
      );
      return;
    }

    try {
      const newPet = await PetModel.create({
        shelter_id: userId,
        publisher_type: 'individual_rescuer',
        name: body.name,
        species: body.species || 'dog',
        breed: body.breed || 'Mestizo',
        age_years: typeof body.age_years === 'number' ? body.age_years : 1.0,
        gender: body.gender || 'male',
        size: body.size || 'medium',
        energy_level: body.energy_level || 3,

        origin: 'relinquished',
        is_litter: false,
        weaning_completed: true,

        is_vaccinated: Boolean(body.is_vaccinated),
        vaccines_applied: Array.isArray(body.vaccines_applied) ? body.vaccines_applied : [],
        dewormed_internal: Boolean(body.dewormed_internal),
        dewormed_external: Boolean(body.dewormed_external),
        has_microchip: Boolean(body.has_microchip),
        is_neutered: Boolean(body.is_neutered),
        reproductive_status: body.reproductive_status || (body.is_neutered ? 'neutered' : 'intact'),

        house_trained: body.house_trained ?? true,
        good_with_dogs: body.good_with_dogs ?? true,
        good_with_cats: body.good_with_cats ?? true,
        good_with_kids: body.good_with_kids ?? true,
        requires_yard: Boolean(body.requires_yard),
        storm_anxiety: body.storm_anxiety || 1,
        special_needs: body.special_needs || null,
        story: `Reubicación Responsable: ${body.story}`,
        relocation_reason: body.relocation_reason.trim(),

        requires_adoption_contract: true,
        requires_home_check: Boolean(body.requires_home_check),
        requires_followup_photos: true,
        delivery_type: body.delivery_type || 'to_be_agreed',

        photos: Array.isArray(body.photos) ? body.photos : [],
        status: 'available',
        moderation_status: 'pending',
        latitude: typeof body.latitude === 'number' ? body.latitude : null,
        longitude: typeof body.longitude === 'number' ? body.longitude : null,
      });

      ResponseView.success(
        res,
        newPet,
        'Solicitud de reubicación enviada. Un moderador la revisará antes de publicarla.',
        201
      );
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Listar mascotas pendientes de moderación (solo admin)
   */
  static async getPendingModeration(req: AuthenticatedRequest, res: Response): Promise<void> {
    if (req.user?.role !== 'admin') {
      ResponseView.forbidden(res, 'Solo un administrador puede ver la cola de moderación');
      return;
    }

    try {
      const pets = await PetModel.findPendingModeration();
      ResponseView.success(res, pets, 'Mascotas pendientes de moderación');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Aprobar o rechazar una mascota pendiente de moderación (solo admin)
   */
  static async moderatePet(req: AuthenticatedRequest, res: Response): Promise<void> {
    if (req.user?.role !== 'admin') {
      ResponseView.forbidden(res, 'Solo un administrador puede moderar publicaciones');
      return;
    }

    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const { moderation_status, moderation_notes } = req.body;

    if (!id || !['approved', 'rejected'].includes(moderation_status)) {
      ResponseView.error(res, 'moderation_status debe ser "approved" o "rejected"', 400);
      return;
    }

    try {
      const updated = await PetModel.moderate(id, moderation_status, moderation_notes);
      await AuditLogModel.record(req.user!.id, `pet_moderation_${moderation_status}`, 'pets', id, {
        moderation_notes: moderation_notes || null,
      });
      ResponseView.success(res, updated, 'Moderación aplicada correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
