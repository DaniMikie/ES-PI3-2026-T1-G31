/**
 * Testes: constantes do módulo startups
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {allowedStages, allowedVisibilities} from "../../../startups/shared/constants";

describe("allowedStages", () => {
  it("deve conter exatamente 3 estágios válidos", () => {
    expect(allowedStages).toHaveLength(3);
    expect(allowedStages).toContain("nova");
    expect(allowedStages).toContain("em_operacao");
    expect(allowedStages).toContain("em_expansao");
  });
});

describe("allowedVisibilities", () => {
  it("deve conter exatamente 2 visibilidades válidas", () => {
    expect(allowedVisibilities).toHaveLength(2);
    expect(allowedVisibilities).toContain("publica");
    expect(allowedVisibilities).toContain("privada");
  });
});
