import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock();

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { MessageController } = await import('../controllers/message.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('MessageController.send', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza un mensaje vacío', async () => {
    const req = { user: { id: 'u1' }, params: { matchId: 'm1' }, body: { content: '   ' } };
    const res = mockRes();

    await MessageController.send(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza (422) un mensaje que supera los 3000 caracteres', async () => {
    const req = {
      user: { id: 'u1' },
      params: { matchId: 'm1' },
      body: { content: 'x'.repeat(3001) },
    };
    const res = mockRes();

    await MessageController.send(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });

  it('rechaza (422) un mensaje con lenguaje no permitido', async () => {
    const req = {
      user: { id: 'u1' },
      params: { matchId: 'm1' },
      body: { content: 'te voy a matar' },
    };
    const res = mockRes();

    await MessageController.send(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });
});
