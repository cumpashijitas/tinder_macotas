import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, createQueryBuilderMock, lastBuilderFor } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock({
  adoption_contracts: {
    data: {
      id: 'contract-1',
      match_id: 'match-1',
      adopter_id: 'adopter-1',
      shelter_id: 'shelter-1',
      signed_by_adopter: false,
      signed_by_shelter: false,
      signature_hash: null,
    },
    error: null,
  },
});

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { ContractController } = await import('../controllers/contract.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('ContractController.sign', () => {
  beforeEach(() => vi.clearAllMocks());

  it('registra la firma en audit_logs con el firmante como actor', async () => {
    const req = { user: { id: 'adopter-1' }, params: { matchId: 'match-1' } };
    const res = mockRes();

    await ContractController.sign(req as never, res as never);

    const auditBuilder = lastBuilderFor(mockAdmin, 'audit_logs');
    const logPayload = auditBuilder.insert.mock.calls[0][0];
    expect(logPayload.actor_id).toBe('adopter-1');
    expect(logPayload.action).toBe('contract_signed');
    expect(logPayload.target_table).toBe('adoption_contracts');
    expect(logPayload.target_id).toBe('contract-1');
  });

  it('rechaza si el usuario no participa del match', async () => {
    const req = { user: { id: 'otro-usuario' }, params: { matchId: 'match-1' } };
    const res = mockRes();

    await ContractController.sign(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('ContractController.get (cross-tenant)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza (403) leer el contrato de un match del que no se participa', async () => {
    const req = { user: { id: 'usuario-ajeno' }, params: { matchId: 'match-1' } };
    const res = mockRes();

    // matches/getMatch con el mock por default devuelve null → no participante
    await ContractController.get(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('ContractController.create (cross-tenant)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza (403) iniciar un contrato en un match cuyo refugio no es el usuario actual', async () => {
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('matches');
      return createQueryBuilderMock({
        data: { adopter_id: 'adopter-1', shelter_id: 'shelter-1', status: 'approved_for_chat' },
        error: null,
      });
    });

    const req = { user: { id: 'shelter-2' }, params: { matchId: 'match-1' } };
    const res = mockRes();

    await ContractController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('ContractController.listAll', () => {
  beforeEach(() => vi.clearAllMocks());

  it('incluye limit/offset/hasMore en meta', async () => {
    const req = { user: { id: 'adopter-1' }, query: {} };
    const res = mockRes();

    await ContractController.listAll(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        meta: expect.objectContaining({ limit: 50, offset: 0 }),
      })
    );
  });
});
