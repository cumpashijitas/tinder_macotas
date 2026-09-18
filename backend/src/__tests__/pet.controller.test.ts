import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, lastBuilderFor, createQueryBuilderMock } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock();

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { PetController } = await import('../controllers/pet.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('PetController.create', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza si el usuario no tiene rol autorizado para publicar', async () => {
    const req = { user: { id: 'u1', role: 'adopter' }, body: { name: 'Firulais' } };
    const res = mockRes();

    await PetController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  it('rechaza cachorros de camada sin cumplir el destete ético mínimo de 60 días', async () => {
    const req = {
      user: { id: 'u1', role: 'individual_rescuer' },
      body: { name: 'Cachorro', is_litter: true, age_years: 0.1, weaning_completed: false },
    };
    const res = mockRes();

    await PetController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });

  it('crea la mascota como moderation_status "approved" para publicaciones normales', async () => {
    const req = {
      user: { id: 'shelter-1', role: 'shelter' },
      body: { name: 'Rocky', species: 'dog' },
    };
    const res = mockRes();

    await PetController.create(req as never, res as never);

    const petsBuilder = lastBuilderFor(mockAdmin, 'pets');
    const insertedPayload = petsBuilder.insert.mock.calls[0][0];
    expect(insertedPayload.moderation_status).toBe('approved');
    expect(insertedPayload.shelter_id).toBe('shelter-1');
  });

  it('rechaza (422) un age_years fuera de rango en vez de dejarlo llegar a Postgres', async () => {
    const req = {
      user: { id: 'shelter-1', role: 'shelter' },
      body: { name: 'Rocky', species: 'dog', age_years: -5 },
    };
    const res = mockRes();

    await PetController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });

  it('rechaza (422) una foto que no es una URL válida', async () => {
    const req = {
      user: { id: 'shelter-1', role: 'shelter' },
      body: { name: 'Rocky', species: 'dog', photos: ['no-es-una-url'] },
    };
    const res = mockRes();

    await PetController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });

  it('rechaza (422) latitude/longitude fuera de rango', async () => {
    const req = {
      user: { id: 'shelter-1', role: 'shelter' },
      body: { name: 'Rocky', species: 'dog', latitude: 500 },
    };
    const res = mockRes();

    await PetController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });
});

describe('PetController.getFeed', () => {
  beforeEach(() => vi.clearAllMocks());

  it('incluye limit/offset/hasMore en meta usando los defaults cuando no vienen en la query', async () => {
    const req = { user: { id: 'adopter-1' }, query: {} };
    const res = mockRes();

    await PetController.getFeed(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        meta: { limit: 20, offset: 0, hasMore: false },
      })
    );
  });

  it('respeta limit/offset pedidos por query string', async () => {
    const req = { user: { id: 'adopter-1' }, query: { limit: '5', offset: '10' } };
    const res = mockRes();

    await PetController.getFeed(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        meta: expect.objectContaining({ limit: 5, offset: 10 }),
      })
    );
  });
});

describe('PetController.relocatePet', () => {
  beforeEach(() => vi.clearAllMocks());

  it('exige un motivo de reubicación de al menos 15 caracteres', async () => {
    const req = {
      user: { id: 'u1' },
      body: { name: 'Max', relocation_reason: 'mudanza' },
    };
    const res = mockRes();

    await PetController.relocatePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });

  it('envía la mascota a moderation_status "pending" (cola de revisión)', async () => {
    const req = {
      user: { id: 'u1' },
      body: { name: 'Max', story: 'Buen perro', relocation_reason: 'Mudanza al exterior por trabajo' },
    };
    const res = mockRes();

    await PetController.relocatePet(req as never, res as never);

    const petsBuilder = lastBuilderFor(mockAdmin, 'pets');
    const insertedPayload = petsBuilder.insert.mock.calls[0][0];
    expect(insertedPayload.moderation_status).toBe('pending');
    expect(insertedPayload.origin).toBe('relinquished');
  });
});

describe('PetController.updatePet', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza si no se envía ningún campo editable', async () => {
    const req = { user: { id: 'u1' }, params: { id: 'pet-1' }, body: { status: 'adopted' } };
    const res = mockRes();

    await PetController.updatePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('sólo incluye los campos editables permitidos en el patch (ignora status/moderation)', async () => {
    const req = {
      user: { id: 'u1' },
      params: { id: 'pet-1' },
      body: { name: 'Nuevo Nombre', status: 'adopted', moderation_status: 'rejected', shelter_id: 'otro' },
    };
    const res = mockRes();

    await PetController.updatePet(req as never, res as never);

    const petsBuilder = lastBuilderFor(mockAdmin, 'pets');
    const patch = petsBuilder.update.mock.calls[0][0];
    expect(patch.name).toBe('Nuevo Nombre');
    expect(patch.status).toBeUndefined();
    expect(patch.moderation_status).toBeUndefined();
    expect(patch.shelter_id).toBeUndefined();
  });

  it('devuelve 404 si la mascota no existe o no pertenece al usuario', async () => {
    const req = { user: { id: 'u1' }, params: { id: 'pet-1' }, body: { name: 'X' } };
    const res = mockRes();

    await PetController.updatePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  it('rechaza (422) un energy_level fuera de rango antes de tocar la base', async () => {
    const req = { user: { id: 'u1' }, params: { id: 'pet-1' }, body: { energy_level: 9 } };
    const res = mockRes();

    await PetController.updatePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });
});

describe('PetController.deletePet', () => {
  beforeEach(() => vi.clearAllMocks());

  it('bloquea el borrado si la mascota ya tiene matches (409)', async () => {
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('matches');
      return createQueryBuilderMock({ data: null, error: null, count: 2 });
    });

    const req = { user: { id: 'u1' }, params: { id: 'pet-1' } };
    const res = mockRes();

    await PetController.deletePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(409);
  });

  it('elimina la mascota cuando no tiene matches', async () => {
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('matches');
      return createQueryBuilderMock({ data: null, error: null, count: 0 });
    });
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('pets');
      return createQueryBuilderMock({ data: null, error: null, count: 1 });
    });

    const req = { user: { id: 'u1' }, params: { id: 'pet-1' } };
    const res = mockRes();

    await PetController.deletePet(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: true })
    );
  });
});

describe('PetController.moderatePet', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza si el usuario no es admin', async () => {
    const req = { user: { id: 'u1', role: 'shelter' }, params: { id: 'pet-1' }, body: { moderation_status: 'approved' } };
    const res = mockRes();

    await PetController.moderatePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  it('rechaza un moderation_status inválido', async () => {
    const req = { user: { id: 'admin-1', role: 'admin' }, params: { id: 'pet-1' }, body: { moderation_status: 'maybe' } };
    const res = mockRes();

    await PetController.moderatePet(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('permite a un admin aprobar una mascota pendiente', async () => {
    const req = { user: { id: 'admin-1', role: 'admin' }, params: { id: 'pet-1' }, body: { moderation_status: 'approved' } };
    const res = mockRes();

    await PetController.moderatePet(req as never, res as never);

    const petsBuilder = lastBuilderFor(mockAdmin, 'pets');
    const updatedPayload = petsBuilder.update.mock.calls[0][0];
    expect(updatedPayload.moderation_status).toBe('approved');
  });

  it('registra la moderación en audit_logs con el admin como actor', async () => {
    const req = { user: { id: 'admin-1', role: 'admin' }, params: { id: 'pet-1' }, body: { moderation_status: 'rejected', moderation_notes: 'Fotos poco claras' } };
    const res = mockRes();

    await PetController.moderatePet(req as never, res as never);

    const auditBuilder = lastBuilderFor(mockAdmin, 'audit_logs');
    const logPayload = auditBuilder.insert.mock.calls[0][0];
    expect(logPayload.actor_id).toBe('admin-1');
    expect(logPayload.action).toBe('pet_moderation_rejected');
    expect(logPayload.target_table).toBe('pets');
    expect(logPayload.target_id).toBe('pet-1');
  });
});
