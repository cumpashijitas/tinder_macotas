import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, lastBuilderFor } from './helpers/supabaseMock.js';

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
});
