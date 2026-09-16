import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, lastBuilderFor } from './helpers/supabaseMock.js';
import type { ContractRecord } from '../models/contract.model.js';

function baseContract(overrides: Partial<ContractRecord> = {}): ContractRecord {
  return {
    id: 'contract-1',
    match_id: 'match-1',
    adopter_id: 'adopter-1',
    shelter_id: 'shelter-1',
    terms_version: 'v1',
    signed_by_adopter: false,
    signed_by_adopter_at: null,
    signed_by_shelter: false,
    signed_by_shelter_at: null,
    signature_hash: null,
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

describe('ContractModel.sign', () => {
  beforeEach(() => vi.resetModules());

  it('firma únicamente la parte del adoptante y NO finaliza la adopción todavía', async () => {
    const mockAdmin = createSupabaseAdminMock({
      adoption_contracts: { data: { ...baseContract(), signed_by_adopter: true }, error: null },
    });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { ContractModel } = await import('../models/contract.model.js');

    await ContractModel.sign(baseContract(), 'adopter-1');

    const contractsBuilder = lastBuilderFor(mockAdmin, 'adoption_contracts');
    const patch = contractsBuilder.update.mock.calls[0][0];

    expect(patch.signed_by_adopter).toBe(true);
    expect(patch.signature_hash).toBeUndefined();

    const calledMatches = mockAdmin.from.mock.calls.some((c: unknown[]) => c[0] === 'matches');
    expect(calledMatches).toBe(false);
  });

  it('al firmar la segunda parte, genera el hash y finaliza la adopción', async () => {
    const mockAdmin = createSupabaseAdminMock({
      adoption_contracts: {
        data: { ...baseContract(), signed_by_adopter: true, signed_by_shelter: true },
        error: null,
      },
      matches: { data: { id: 'match-1', status: 'adoption_finalized' }, error: null },
    });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { ContractModel } = await import('../models/contract.model.js');

    const alreadySignedByAdopter = baseContract({ signed_by_adopter: true, signed_by_adopter_at: '2026-01-02T00:00:00.000Z' });
    await ContractModel.sign(alreadySignedByAdopter, 'shelter-1');

    const contractsBuilder = lastBuilderFor(mockAdmin, 'adoption_contracts');
    const patch = contractsBuilder.update.mock.calls[0][0];

    expect(patch.signed_by_shelter).toBe(true);
    expect(typeof patch.signature_hash).toBe('string');
    expect(patch.signature_hash.length).toBeGreaterThan(0);

    const matchesBuilder = lastBuilderFor(mockAdmin, 'matches');
    expect(matchesBuilder.update.mock.calls[0][0].status).toBe('adoption_finalized');
  });

  it('no regenera el hash si el contrato ya estaba completamente firmado', async () => {
    const mockAdmin = createSupabaseAdminMock({
      adoption_contracts: { data: baseContract(), error: null },
    });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { ContractModel } = await import('../models/contract.model.js');

    const fullySigned = baseContract({
      signed_by_adopter: true,
      signed_by_shelter: true,
      signature_hash: 'existing-hash',
    });
    await ContractModel.sign(fullySigned, 'adopter-1');

    const contractsBuilder = lastBuilderFor(mockAdmin, 'adoption_contracts');
    const patch = contractsBuilder.update.mock.calls[0][0];

    expect(patch.signature_hash).toBeUndefined();
  });
});
