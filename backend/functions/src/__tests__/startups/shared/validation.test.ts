/**
 * Testes: normalizeString — validação de strings
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {normalizeString} from "../../../startups/shared/validation";

describe("normalizeString", () => {
  it("deve retornar undefined para valores não-string", () => {
    expect(normalizeString(undefined)).toBeUndefined();
    expect(normalizeString(null)).toBeUndefined();
    expect(normalizeString(123)).toBeUndefined();
    expect(normalizeString(true)).toBeUndefined();
  });

  it("deve retornar undefined para strings vazias ou só espaços", () => {
    expect(normalizeString("")).toBeUndefined();
    expect(normalizeString("   ")).toBeUndefined();
  });

  it("deve retornar string trimada para valores válidos", () => {
    expect(normalizeString("  hello  ")).toBe("hello");
    expect(normalizeString("teste")).toBe("teste");
  });
});
