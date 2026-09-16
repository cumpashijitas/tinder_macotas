import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock } from './helpers/supabaseMock.js';

function setupMock(matchesError: { message: string } | null = null) {
  const mockAdmin = createSupabaseAdminMock({
    swipes: { data: { id: 'swipe-1', adopter_id: 'adopter-1', pet_id: 'pet-1', direction: 'right' }, error: null },
    pets: { data: { shelter_id: 'shelter-1' }, error: null },
    matches: { data: null, error: matchesError },
  });
  return mockAdmin;
}

describe('SwipeModel.recordSwipe', () => {
  beforeEach(() => vi.resetModules());

  it('no crea match en un swipe hacia la izquierda', async () => {
    const mockAdmin = setupMock();
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { SwipeModel } = await import('../models/swipe.model.js');

    const result = await SwipeModel.recordSwipe('adopter-1', 'pet-1', 'left');

    expect(result.matchCreated).toBe(false);
    const calledMatches = mockAdmin.from.mock.calls.some((c: unknown[]) => c[0] === 'matches');
    expect(calledMatches).toBe(false);
  });

  it('crea match en un swipe hacia la derecha', async () => {
    const mockAdmin = setupMock();
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { SwipeModel } = await import('../models/swipe.model.js');

    const result = await SwipeModel.recordSwipe('adopter-1', 'pet-1', 'right');

    expect(result.matchCreated).toBe(true);
  });

  it('crea match en un superlike', async () => {
    const mockAdmin = setupMock();
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { SwipeModel } = await import('../models/swipe.model.js');

    const result = await SwipeModel.recordSwipe('adopter-1', 'pet-1', 'superlike');

    expect(result.matchCreated).toBe(true);
  });

  it('no marca matchCreated si la inserción del match falla', async () => {
    const mockAdmin = setupMock({ message: 'duplicate key' });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { SwipeModel } = await import('../models/swipe.model.js');

    const result = await SwipeModel.recordSwipe('adopter-1', 'pet-1', 'right');

    expect(result.matchCreated).toBe(false);
  });
});
