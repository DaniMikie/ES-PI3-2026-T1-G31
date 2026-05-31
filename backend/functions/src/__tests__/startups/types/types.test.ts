/**
 * Testes: tipos do módulo startups — validação de estrutura
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {
  StartupStage,
  QuestionVisibility,
  AuthenticatedUser,
  Founder,
  StartupDocument,
  StartupListItem,
} from "../../../startups/types";

describe("Tipos do módulo startups", () => {
  it("deve aceitar StartupStage válidos", () => {
    const stages: StartupStage[] = ["nova", "em_operacao", "em_expansao"];
    expect(stages).toHaveLength(3);
  });

  it("deve aceitar QuestionVisibility válidos", () => {
    const visibilities: QuestionVisibility[] = ["publica", "privada"];
    expect(visibilities).toHaveLength(2);
  });

  it("deve criar AuthenticatedUser com uid e email", () => {
    const user: AuthenticatedUser = {uid: "abc", email: "a@b.com"};
    expect(user.uid).toBe("abc");
    expect(user.email).toBe("a@b.com");
  });

  it("deve criar AuthenticatedUser sem email", () => {
    const user: AuthenticatedUser = {uid: "abc"};
    expect(user.uid).toBe("abc");
    expect(user.email).toBeUndefined();
  });

  it("deve criar Founder com campos obrigatórios", () => {
    const founder: Founder = {name: "Ana", role: "CEO", equityPercent: 60};
    expect(founder.name).toBe("Ana");
    expect(founder.equityPercent).toBe(60);
  });

  it("deve criar StartupListItem com campos resumidos", () => {
    const item: StartupListItem = {
      id: "test-1",
      name: "Startup Teste",
      shortDescription: "Descrição curta",
      stage: "nova",
      capitalRaisedCents: 10000,
      totalTokensIssued: 500,
      currentTokenPriceCents: 100,
      tags: ["tech"],
    };
    expect(item.id).toBe("test-1");
    expect(item.tags).toContain("tech");
  });

  it("deve criar StartupDocument completo", () => {
    const doc: StartupDocument = {
      name: "Startup Completa",
      stage: "em_operacao",
      shortDescription: "Curta",
      description: "Longa",
      executiveSummary: "Sumário",
      capitalRaisedCents: 50000,
      totalTokensIssued: 1000,
      currentTokenPriceCents: 200,
      founders: [{name: "João", role: "CEO", equityPercent: 100}],
      externalMembers: [],
      demoVideos: [],
      tags: ["fintech"],
    };
    expect(doc.name).toBe("Startup Completa");
    expect(doc.founders).toHaveLength(1);
  });
});
