import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';

// Valida formato y rango de los campos que puede enviar el cliente al crear o
// editar una mascota. Espeja los CHECK de 01_schema.sql/05_extended_schema.sql
// para devolver un mensaje claro en vez del error crudo de Postgres. Todos los
// campos son opcionales acá: los requeridos y los valores por defecto los
// sigue resolviendo el controller, esto sólo rechaza datos con formato inválido.
export const PetInputSchema = z.object({
  name: z.string().trim().min(1, 'El nombre no puede estar vacío').max(80, 'El nombre es demasiado largo (máx. 80 caracteres)').optional(),
  species: z.enum(['dog', 'cat', 'other']).optional(),
  breed: z.string().trim().max(80, 'La raza es demasiado larga (máx. 80 caracteres)').optional(),
  age_years: z.number().min(0, 'La edad no puede ser negativa').max(30, 'La edad ingresada no es realista (máx. 30 años)').optional(),
  gender: z.enum(['male', 'female']).optional(),
  size: z.enum(['small', 'medium', 'large', 'giant']).optional(),
  energy_level: z.number().int('El nivel de energía debe ser un número entero').min(1).max(5, 'El nivel de energía debe estar entre 1 y 5').optional(),
  origin: z.enum(['home_litter', 'street_rescue', 'shelter_born', 'relinquished']).optional(),
  birth_date: z.string().nullable().optional(),
  vaccines_applied: z.array(z.string().trim().min(1).max(100)).max(20, 'Máximo 20 vacunas registradas').optional(),
  reproductive_status: z.enum(['neutered', 'spayed', 'requires_spay_agreement', 'intact']).optional(),
  storm_anxiety: z.number().int('El nivel de ansiedad a tormentas debe ser un número entero').min(1).max(5, 'El nivel de ansiedad a tormentas debe estar entre 1 y 5').optional(),
  special_needs: z.string().trim().max(1000, 'Las necesidades especiales no pueden superar los 1000 caracteres').nullable().optional(),
  story: z.string().trim().max(2000, 'La historia no puede superar los 2000 caracteres').optional(),
  delivery_type: z.enum(['pickup_at_shelter', 'home_delivery', 'to_be_agreed']).optional(),
  photos: z.array(z.string().trim().url('Cada foto debe ser una URL válida')).max(12, 'Máximo 12 fotos por mascota').optional(),
  latitude: z.number().min(-90, 'La latitud debe estar entre -90 y 90').max(90, 'La latitud debe estar entre -90 y 90').nullable().optional(),
  longitude: z.number().min(-180, 'La longitud debe estar entre -180 y 180').max(180, 'La longitud debe estar entre -180 y 180').nullable().optional(),
});

export interface PetRecord {
  id: string;
  shelter_id: string; // ID del publicador (refugio o particular)
  publisher_type: 'shelter' | 'individual_rescuer';
  name: string;
  species: 'dog' | 'cat' | 'other';
  breed: string;
  age_years: number;
  gender: 'male' | 'female';
  size: 'small' | 'medium' | 'large' | 'giant';
  energy_level: number;

  // Origen y Camadas
  origin: 'home_litter' | 'street_rescue' | 'shelter_born' | 'relinquished';
  is_litter: boolean;
  birth_date?: string | null;
  weaning_completed: boolean; // Destete completado (mínimo 60 días)

  // Plan Sanitario y Reproducción
  is_vaccinated: boolean;
  vaccines_applied: string[]; // Ej: ['Antirrábica', 'Séxtuple', 'Triple Felina']
  dewormed_internal: boolean;
  dewormed_external: boolean; // Pipeta contra pulgas/garrapatas
  has_microchip: boolean;
  is_neutered: boolean;
  reproductive_status: 'neutered' | 'spayed' | 'requires_spay_agreement' | 'intact';

  // Hábitos y Comportamiento
  house_trained: boolean;
  good_with_dogs: boolean;
  good_with_cats: boolean;
  good_with_kids: boolean;
  requires_yard: boolean;
  storm_anxiety: number; // 1 (sin miedo) a 5 (pánico severo)
  special_needs?: string | null;
  story: string;

  // Requisitos de Entrega
  requires_adoption_contract: boolean;
  requires_home_check: boolean;
  requires_followup_photos: boolean;
  delivery_type: 'pickup_at_shelter' | 'home_delivery' | 'to_be_agreed';

  photos: string[];
  status: 'available' | 'paused' | 'in_process' | 'adopted';
  relocation_reason?: string | null;
  moderation_status: 'pending' | 'approved' | 'rejected';
  moderation_notes?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  created_at: string;
  updated_at: string;
}

export class PetModel {
  static async findById(id: string): Promise<PetRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data as PetRecord | null;
  }

  /**
   * Obtiene las mascotas disponibles para un adoptante que aún NO hayan sido swipéadas
   * Permite filtrar opcionalmente por especie y tipo de publicador (refugio o camada particular)
   */
  static async getFeedForAdopter(
    adopterId: string,
    options: { limit?: number; offset?: number; species?: string; publisherType?: string } = {}
  ): Promise<{ items: PetRecord[]; hasMore: boolean }> {
    const limit = options.limit || 20;
    const offset = options.offset || 0;

    // 1. Obtener IDs de mascotas ya swipéadas por este usuario
    const { data: swipedPets, error: swipeError } = await supabaseAdmin
      .from('swipes')
      .select('pet_id')
      .eq('adopter_id', adopterId);

    if (swipeError) throw swipeError;

    const excludedPetIds = (swipedPets || []).map((s) => s.pet_id);

    // 2. Consultar mascotas disponibles. Se pide una fila de más
    // (offset..offset+limit) para saber si hay una página siguiente sin
    // necesitar un COUNT aparte.
    let query = supabaseAdmin
      .from('pets')
      .select('*')
      .eq('status', 'available')
      .eq('moderation_status', 'approved')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit);

    if (options.species) {
      query = query.eq('species', options.species);
    }

    if (options.publisherType) {
      query = query.eq('publisher_type', options.publisherType);
    }

    if (excludedPetIds.length > 0) {
      query = query.not('id', 'in', `(${excludedPetIds.join(',')})`);
    }

    const { data, error } = await query;
    if (error) throw error;

    const rows = (data || []) as PetRecord[];
    const hasMore = rows.length > limit;
    return { items: hasMore ? rows.slice(0, limit) : rows, hasMore };
  }

  static async create(pet: Omit<PetRecord, 'id' | 'created_at' | 'updated_at'>): Promise<PetRecord> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .insert(pet)
      .select()
      .single();

    if (error) throw error;
    return data as PetRecord;
  }

  /**
   * `maybeSingle` a propósito: si el ID no existe o pertenece a otro
   * publicador, el filtro `shelter_id` no matchea ninguna fila y esto debe
   * devolver `null` (404 en el controller) en vez de que `.single()` lo
   * convierta en un error 500 genérico.
   */
  static async updateStatus(
    id: string,
    shelterId: string,
    status: PetRecord['status']
  ): Promise<PetRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('shelter_id', shelterId)
      .select()
      .maybeSingle();

    if (error) throw error;
    return data as PetRecord | null;
  }

  /**
   * Edita los datos de una mascota publicada (sólo el propio publicador).
   * No permite cambiar campos administrativos (status, moderación, dueño).
   */
  static async update(
    id: string,
    shelterId: string,
    patch: Partial<
      Omit<
        PetRecord,
        'id' | 'shelter_id' | 'publisher_type' | 'status' | 'moderation_status' | 'moderation_notes' | 'created_at' | 'updated_at'
      >
    >
  ): Promise<PetRecord | null> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .update({ ...patch, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('shelter_id', shelterId)
      .select()
      .maybeSingle();

    if (error) throw error;
    return data as PetRecord | null;
  }

  /**
   * Cuenta cuántos matches tiene una mascota (para bloquear el borrado si ya
   * hay postulantes con historial en curso, evitando pérdida de datos).
   */
  static async countMatches(id: string): Promise<number> {
    const { count, error } = await supabaseAdmin
      .from('matches')
      .select('id', { count: 'exact', head: true })
      .eq('pet_id', id);

    if (error) throw error;
    return count || 0;
  }

  static async delete(id: string, shelterId: string): Promise<boolean> {
    const { error, count } = await supabaseAdmin
      .from('pets')
      .delete({ count: 'exact' })
      .eq('id', id)
      .eq('shelter_id', shelterId);

    if (error) throw error;
    return (count || 0) > 0;
  }

  static async findByShelterId(shelterId: string): Promise<PetRecord[]> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .select('*')
      .eq('shelter_id', shelterId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return (data || []) as PetRecord[];
  }

  /**
   * Mascotas pendientes de moderación (ej. solicitudes de reubicación responsable)
   */
  static async findPendingModeration(): Promise<PetRecord[]> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .select('*')
      .eq('moderation_status', 'pending')
      .order('created_at', { ascending: true });

    if (error) throw error;
    return (data || []) as PetRecord[];
  }

  static async moderate(
    id: string,
    moderationStatus: 'approved' | 'rejected',
    moderationNotes?: string | null
  ): Promise<PetRecord> {
    const { data, error } = await supabaseAdmin
      .from('pets')
      .update({
        moderation_status: moderationStatus,
        moderation_notes: moderationNotes || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data as PetRecord;
  }
}
