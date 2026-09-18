import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, lastBuilderFor } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock({
  notifications: {
    data: [{ id: 'n1', user_id: 'u1', type: 'new_message', title: 'Nuevo mensaje', is_read: false }],
    error: null,
    count: 3,
  },
});

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { NotificationController } = await import('../controllers/notification.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('NotificationController.list', () => {
  beforeEach(() => vi.clearAllMocks());

  it('exige autenticación', async () => {
    const req = { user: undefined };
    const res = mockRes();

    await NotificationController.list(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  it('devuelve las notificaciones junto con el conteo de no leídas', async () => {
    const req = { user: { id: 'u1' } };
    const res = mockRes();

    await NotificationController.list(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          notifications: expect.any(Array),
          unreadCount: 3,
          hasMore: false,
        }),
        meta: { limit: 50, offset: 0 },
      })
    );
  });
});

describe('NotificationController.markRead', () => {
  beforeEach(() => vi.clearAllMocks());

  it('marca sólo la notificación del propio usuario como leída', async () => {
    const req = { user: { id: 'u1' }, params: { id: 'n1' } };
    const res = mockRes();

    await NotificationController.markRead(req as never, res as never);

    const builder = lastBuilderFor(mockAdmin, 'notifications');
    expect(builder.update).toHaveBeenCalledWith({ is_read: true });
    expect(builder.eq).toHaveBeenCalledWith('id', 'n1');
    expect(builder.eq).toHaveBeenCalledWith('user_id', 'u1');
  });
});
