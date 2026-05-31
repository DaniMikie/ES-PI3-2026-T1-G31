/**
 * Testes: getStartupTokenHistory — gráfico de preço de uma startup
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Testa o cálculo do preço médio por período:
 * - Agrupa transações por hora/dia/semana/mês
 * - Calcula média ponderada (totalCents / totalQty)
 * - Adiciona preço atual como último ponto
 * - Calcula variação % entre primeiro e último ponto
 */

jest.mock("firebase-admin/app", () => ({
  getApps: jest.fn(() => [{}]),
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(() => ({})),
}));

const mockCollectionGroupGet = jest.fn();
const mockStartupDocGet = jest.fn();

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collectionGroup: jest.fn(() => ({
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      get: mockCollectionGroupGet,
    })),
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: mockStartupDocGet,
      })),
    })),
  })),
  FieldValue: {
    serverTimestamp: jest.fn(() => "MOCK_TIMESTAMP"),
  },
  Timestamp: {},
}));

jest.mock("../../../startups/shared/auth", () => ({
  requireAuthenticatedUser: jest.fn(() => ({uid: "user-123", email: "dani@test.com"})),
}));

jest.mock("../../../startups/shared/validation", () => ({
  normalizeString: jest.fn((s: string) => s?.trim() || ""),
}));

// Helper pra criar documentos fake
function createDoc(priceCents: number, quantity: number, type: string, hoursAgo: number) {
  const date = new Date();
  date.setHours(date.getHours() - hoursAgo);
  return {
    data: () => ({
      priceCents,
      quantity,
      type,
      startupId: "agrosmart",
      createdAt: {toDate: () => date},
    }),
  };
}

describe("getStartupTokenHistory — preço médio por período", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Preço atual da startup no Firestore
    mockStartupDocGet.mockResolvedValue({
      data: () => ({currentTokenPriceCents: 289}),
    });
  });

  it("deve retornar array vazio quando não tem transações", async () => {
    mockCollectionGroupGet.mockResolvedValue({empty: true, docs: []});

    const {getStartupTokenHistory} = require("../../../exchange/handlers/getStartupTokenHistory");

    const result = await getStartupTokenHistory.run({
      data: {startupId: "agrosmart", period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    expect(result.data.points).toEqual([]);
    expect(result.data.variation).toBe(0);
  });

  it("deve calcular preço médio ponderado corretamente", async () => {
    // 2 transações na mesma hora: 10 tokens a R$2,00 e 5 tokens a R$4,00
    // Média ponderada: (2000 + 2000) / (10 + 5) = 4000/15 ≈ 267
    const now = new Date();
    mockCollectionGroupGet.mockResolvedValue({
      empty: false,
      docs: [
        {
          data: () => ({
            priceCents: 200, quantity: 10, type: "buy", startupId: "agrosmart",
            createdAt: {toDate: () => now},
          }),
        },
        {
          data: () => ({
            priceCents: 400, quantity: 5, type: "buy", startupId: "agrosmart",
            createdAt: {toDate: () => now},
          }),
        },
      ],
    });

    const {getStartupTokenHistory} = require("../../../exchange/handlers/getStartupTokenHistory");

    const result = await getStartupTokenHistory.run({
      data: {startupId: "agrosmart", period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.points;
    // Deve ter o ponto agrupado + ponto "atual" (289)
    expect(points.length).toBeGreaterThanOrEqual(2);
    // Média ponderada: (200×10 + 400×5) / (10+5) = 4000/15 ≈ 267
    const avgPoint = points.find((p: {label: string}) => p.label !== "atual" && p.label !== "início");
    if (avgPoint) {
      expect(avgPoint.value).toBe(Math.round(4000 / 15));
    }
  });

  it("deve adicionar preço atual como último ponto", async () => {
    mockCollectionGroupGet.mockResolvedValue({
      empty: false,
      docs: [createDoc(300, 10, "buy", 2)],
    });

    const {getStartupTokenHistory} = require("../../../exchange/handlers/getStartupTokenHistory");

    const result = await getStartupTokenHistory.run({
      data: {startupId: "agrosmart", period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.points;
    const lastPoint = points[points.length - 1];
    // Último ponto deve ser o preço atual (289 centavos = R$2,89)
    expect(lastPoint.label).toBe("atual");
    expect(lastPoint.value).toBe(289);
  });

  it("deve ignorar transações de crédito", async () => {
    mockCollectionGroupGet.mockResolvedValue({
      empty: false,
      docs: [
        createDoc(0, 0, "credit", 2),     // Crédito — ignorado
        createDoc(350, 10, "buy", 1),      // Compra válida
      ],
    });

    const {getStartupTokenHistory} = require("../../../exchange/handlers/getStartupTokenHistory");

    const result = await getStartupTokenHistory.run({
      data: {startupId: "agrosmart", period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    // Não deve ter ponto com valor 0 (crédito foi ignorado)
    const points = result.data.points;
    const zeroPoints = points.filter((p: {value: number}) => p.value === 0);
    expect(zeroPoints.length).toBe(0);
  });

  it("deve calcular variação negativa quando preço caiu", async () => {
    // Transação antiga a R$4,00, preço atual R$2,89
    mockCollectionGroupGet.mockResolvedValue({
      empty: false,
      docs: [createDoc(400, 10, "buy", 3)],
    });

    const {getStartupTokenHistory} = require("../../../exchange/handlers/getStartupTokenHistory");

    const result = await getStartupTokenHistory.run({
      data: {startupId: "agrosmart", period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    // Variação: ((289 - 400) / 400) × 100 = -27.75%
    expect(result.data.variation).toBeLessThan(0);
  });
});
