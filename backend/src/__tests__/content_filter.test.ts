import { describe, it, expect } from 'vitest';
import { containsProhibitedContent, findProhibitedTerm } from '../utils/content_filter.js';

describe('content_filter', () => {
  it('detecta un término prohibido sin importar mayúsculas/acentos', () => {
    expect(containsProhibitedContent('Sos un HIJO DE PUTA')).toBe(true);
    expect(containsProhibitedContent('te voy a matar')).toBe(true);
  });

  it('no marca vocabulario legítimo de un contexto de adopción de mascotas', () => {
    expect(containsProhibitedContent('Es una perra muy cariñosa, le encanta jugar')).toBe(false);
    expect(containsProhibitedContent('El gato negro necesita un hogar con jardín')).toBe(false);
    expect(containsProhibitedContent('Hola, ¿podemos coordinar una visita este sábado?')).toBe(false);
  });

  it('findProhibitedTerm devuelve el término encontrado para poder loguearlo', () => {
    expect(findProhibitedTerm('vete a la mierda')).toBe('vete a la mierda');
    expect(findProhibitedTerm('Hola, ¿cómo estás?')).toBeNull();
  });
});
