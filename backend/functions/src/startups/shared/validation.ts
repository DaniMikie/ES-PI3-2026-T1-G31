/**
 * Validações reutilizáveis — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Funções utilitárias para limpar e validar dados recebidos do Flutter.
 * Usadas em todos os handlers antes de processar os dados.
 */

/**
 * Normaliza uma string: remove espaços nas pontas e rejeita valores vazios.
 * - Se não for string → retorna undefined
 * - Se for vazia ou só espaços → retorna undefined
 * - Se for válida → retorna trimada
 */
export function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}
