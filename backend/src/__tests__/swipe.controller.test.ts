import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, createQueryBuilderMock, lastBuilderFor } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock({
  matches: {
    data: { id: 'match-1', adopter_id: 'adopter-1', shelter_id: 'shelter-1', status: 'approved_for_chat', pets: { name: 'Rocky' } },
    error: null,
  },
});

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { SwipeController } = await import('../controllers/swipe.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('SwipeController.updateMatchStatus', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza si el usuario no es un refugio', async () => {
    const req = { user: { id: 'u1', role: 'adopter' }, params: { id: 'match-1' }, body: { status: 'approved_for_chat' } };
    const res = mockRes();

    await SwipeController.updateMatchStatus(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });

  it('registra el cambio de estado en audit_logs con el refugio como actor', async () => {
    const req = {
      user: { id: 'shelter-1', role: 'shelter' },
      params: { id: 'match-1' },
      body: { status: 'approved_for_chat', comments: 'Todo en orden' },
    };
    const res = mockRes();

    await SwipeController.updateMatchStatus(req as never, res as never);

    const auditBuilder = lastBuilderFor(mockAdmin, 'audit_logs');
    const logPayload = auditBuilder.insert.mock.calls[0][0];
    expect(logPayload.actor_id).toBe('shelter-1');
    expect(logPayload.action).toBe('match_status_approved_for_chat');
    expect(logPayload.target_table).toBe('matches');
    expect(logPayload.target_id).toBe('match-1');
  });
});

describe('SwipeController.getMatches', () => {
  beforeEach(() => vi.clearAllMocks());

  it('incluye limit/offset/hasMore en meta', async () => {
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('matches');
      return createQueryBuilderMock({ data: [{ id: 'match-1' }, { id: 'match-2' }], error: null });
    });

    const req = { user: { id: 'adopter-1', role: 'adopter' }, query: { limit: '2' } };
    const res = mockRes();

    await SwipeController.getMatches(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        meta: { limit: 2, offset: 0, hasMore: false },
      })
    );
  });
});
