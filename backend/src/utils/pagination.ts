export interface PaginationParams {
  limit: number;
  offset: number;
}

const MAX_LIMIT = 100;

/**
 * Lee `limit`/`offset` de los query params de la request con límites
 * razonables (para que nadie pida 1.000.000 de filas de una), y aplica un
 * default por endpoint si no vienen.
 */
export function parsePagination(query: Record<string, unknown> | undefined, defaultLimit = 20): PaginationParams {
  const rawLimit = Number(query?.limit);
  const rawOffset = Number(query?.offset);

  const limit = Number.isFinite(rawLimit) && rawLimit > 0 ? Math.min(Math.floor(rawLimit), MAX_LIMIT) : defaultLimit;
  const offset = Number.isFinite(rawOffset) && rawOffset >= 0 ? Math.floor(rawOffset) : 0;

  return { limit, offset };
}
