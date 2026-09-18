/**
 * Lista base de expresiones que no deberían aparecer en texto libre generado
 * por usuarios (mensajes de chat, historias de adopción, ficha de una
 * mascota). Es una primera línea de defensa simple, pensada para bloquear
 * insultos y lenguaje de odio evidentes — no reemplaza moderación humana.
 *
 * Deliberadamente NO incluye palabras ambiguas que son vocabulario legítimo
 * en un contexto de adopción de mascotas (p.ej. "perra" como hembra canina).
 */
const PROHIBITED_TERMS = [
  'hijo de puta',
  'hijueputa',
  'hijoeputa',
  'malparido',
  'malparida',
  'pendejo de mierda',
  'vete a la mierda',
  'puta madre',
  'concha de tu madre',
  'conchetumadre',
  'maricon de mierda',
  'negro de mierda',
  'sudaca de mierda',
  'te voy a matar',
  'te voy a golpear',
  'te voy a cagar a palos',
];

function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, ''); // quita acentos/tildes para no esquivar el filtro
}

/**
 * Devuelve el término prohibido encontrado (para logging/depuración) o
 * `null` si el texto no contiene ninguno de la lista.
 */
export function findProhibitedTerm(text: string): string | null {
  const normalized = normalize(text);
  for (const term of PROHIBITED_TERMS) {
    const pattern = new RegExp(`\\b${normalize(term).replace(/\s+/g, '\\s+')}\\b`, 'i');
    if (pattern.test(normalized)) return term;
  }
  return null;
}

export function containsProhibitedContent(text: string): boolean {
  return findProhibitedTerm(text) !== null;
}
