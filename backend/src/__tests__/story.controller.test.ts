import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock();

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { StoryController } = await import('../controllers/story.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('StoryController.create', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza un título demasiado corto', async () => {
    const req = {
      user: { id: 'u1' },
      body: { pet_name: 'Rocky', title: 'Hola', content: 'x'.repeat(30) },
    };
    const res = mockRes();

    await StoryController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza un título demasiado largo (más de 150 caracteres)', async () => {
    const req = {
      user: { id: 'u1' },
      body: { pet_name: 'Rocky', title: 'x'.repeat(151), content: 'x'.repeat(30) },
    };
    const res = mockRes();

    await StoryController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza un relato demasiado largo (más de 5000 caracteres)', async () => {
    const req = {
      user: { id: 'u1' },
      body: { pet_name: 'Rocky', title: 'Un final feliz', content: 'x'.repeat(5001) },
    };
    const res = mockRes();

    await StoryController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza un nombre de mascota demasiado largo (más de 80 caracteres)', async () => {
    const req = {
      user: { id: 'u1' },
      body: { pet_name: 'x'.repeat(81), title: 'Un final feliz', content: 'x'.repeat(30) },
    };
    const res = mockRes();

    await StoryController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza (422) una historia con lenguaje no permitido en el relato', async () => {
    const req = {
      user: { id: 'u1' },
      body: {
        pet_name: 'Rocky',
        title: 'Un final feliz',
        content: `Fue un proceso hermoso, aunque al principio pensé "vete a la mierda" el trámite, pero valió la pena.`,
      },
    };
    const res = mockRes();

    await StoryController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });
});
