import { describe, it, expect } from 'vitest';
import { parsePagination } from '../utils/pagination.js';

describe('parsePagination', () => {
  it('usa los defaults cuando no viene query', () => {
    expect(parsePagination(undefined)).toEqual({ limit: 20, offset: 0 });
    expect(parsePagination({}, 10)).toEqual({ limit: 10, offset: 0 });
  });

  it('respeta limit/offset válidos', () => {
    expect(parsePagination({ limit: '5', offset: '15' })).toEqual({ limit: 5, offset: 15 });
  });

  it('cae al default si limit/offset no son números válidos', () => {
    expect(parsePagination({ limit: 'abc', offset: 'xyz' }, 20)).toEqual({ limit: 20, offset: 0 });
  });

  it('cae al default si limit es negativo o cero', () => {
    expect(parsePagination({ limit: '0' }, 20).limit).toBe(20);
    expect(parsePagination({ limit: '-5' }, 20).limit).toBe(20);
  });

  it('cae al default (offset 0) si offset es negativo', () => {
    expect(parsePagination({ offset: '-1' }).offset).toBe(0);
  });

  it('topea limit en 100 aunque se pida más', () => {
    expect(parsePagination({ limit: '5000' }).limit).toBe(100);
  });

  it('trunca limit/offset decimales', () => {
    expect(parsePagination({ limit: '7.9', offset: '2.9' })).toEqual({ limit: 7, offset: 2 });
  });
});
