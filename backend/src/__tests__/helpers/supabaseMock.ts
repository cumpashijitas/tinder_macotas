import { vi } from 'vitest';

export interface MockResult {
  data: unknown;
  error: { message: string } | null;
  count?: number;
}

/**
 * Crea un query-builder encadenable que imita a supabase-js (from().select().eq()....)
 * y resuelve con `result` tanto si se hace `await query` como `.single()`/`.maybeSingle()`.
 */
export function createQueryBuilderMock(result: MockResult) {
  const builder: Record<string, unknown> = {};
  const chainMethods = [
    'select', 'insert', 'update', 'upsert', 'delete',
    'eq', 'neq', 'not', 'in', 'order', 'limit',
  ];

  for (const method of chainMethods) {
    builder[method] = vi.fn(() => builder);
  }

  builder.single = vi.fn(() => Promise.resolve(result));
  builder.maybeSingle = vi.fn(() => Promise.resolve(result));
  builder.then = (resolve: (value: MockResult) => unknown, reject?: (reason: unknown) => unknown) =>
    Promise.resolve(result).then(resolve, reject);

  return builder;
}

/**
 * Crea un mock de supabaseAdmin cuyo .from(table) devuelve la respuesta configurada
 * en `responses[table]` (o una por defecto si no se especifica).
 */
export function createSupabaseAdminMock(responses: Record<string, MockResult> = {}) {
  const defaultResult: MockResult = { data: null, error: null };

  return {
    from: vi.fn((table: string) => createQueryBuilderMock(responses[table] || defaultResult)),
    auth: {
      getUser: vi.fn(),
    },
  };
}

/**
 * Devuelve el query-builder de la ÚLTIMA vez que se llamó `.from(table)`
 * sobre un mock creado con createSupabaseAdminMock, para inspeccionar qué
 * payload se le pasó a insert()/update()/upsert().
 */
export function lastBuilderFor(
  mockAdmin: { from: ReturnType<typeof vi.fn> },
  table: string
): Record<string, ReturnType<typeof vi.fn>> {
  const calls = mockAdmin.from.mock.calls as unknown[][];
  let idx = -1;
  for (let i = 0; i < calls.length; i++) {
    if (calls[i][0] === table) idx = i;
  }
  if (idx === -1) {
    throw new Error(`.from("${table}") fue nunca llamado`);
  }
  return mockAdmin.from.mock.results[idx].value;
}
