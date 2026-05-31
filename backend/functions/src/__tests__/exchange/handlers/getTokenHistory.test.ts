/**
 * Testes: getTokenHistory — gráfico de patrimônio acumulado
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Testa o cálculo do patrimônio ao longo do tempo:
 * - Compras aumentam o patrimônio
 * - Vendas diminuem o patrimônio
 * - Créditos são ignorados
 * - Variação % é calculada corretamente
 */

// Mock do Firebase Admin
jest.mock("firebase-admin/app", () => ({
  getApps: jest.fn(() => [{}]),
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(() => ({})),
}));

// Mock do Firestore
const mockWhere = jest.fn().mockReturnThis();
const mockOrderBy = jest.fn().mockReturnThis();
const mockGetDocs = jest.fn();

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        collection: jest.fn(() => ({
          where: mockWhere,
          orderBy: mockOrderBy,
          get: mockGetDocs,
        })),
      })),
    })),
  })),
  FieldValue: {
    serverTimestamp: jest.fn(() => "MOCK_TIMESTAMP"),
  },
  Timestamp: {},
}));

// Mock da autenticação
jest.mock("../../../startups/shared/auth", () => ({
  requireAuthenticatedUser: jest.fn(() => ({uid: "user-123", email: "dani@test.com"})),
}));

// Helper pra criar documentos fake do Firestore
function createTransactionDoc(type: string, priceCents: number, quantity: number, startupId: string, minutesAgo: number) {
  const date = new Date();
  date.setMinutes(date.getMinutes() - minutesAgo);
  return {
    data: () => ({
      type,
      priceCents,
      quantity,
      startupId,
      createdAt: {toDate: () => date},
    }),
  };
}

describe("getTokenHistory — lógica de patrimônio", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("deve retornar array vazio quando não tem transações", async () => {
    mockGetDocs.mockResolvedValue({empty: true, docs: []});

    // Importa o módulo (precisa ser após os mocks)
    const {getTokenHistory} = require("../../../exchange/handlers/getTokenHistory");

    const result = await getTokenHistory.run({
      data: {period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    expect(result.data.points).toEqual([]);
    expect(result.data.variation).toBe(0);
  });

  it("deve calcular patrimônio crescente com compras", async () => {
    // Simula 2 compras: 10 tokens a R$3,00 e depois 5 tokens a R$4,00
    mockGetDocs.mockResolvedValue({
      empty: false,
      docs: [
        createTransactionDoc("buy", 300, 10, "startup-a", 30),  // 10 × 300 = 3000
        createTransactionDoc("buy", 400, 5, "startup-a", 15),   // 15 × 400 = 6000
      ],
    });

    const {getTokenHistory} = require("../../../exchange/handlers/getTokenHistory");

    const result = await getTokenHistory.run({
      data: {period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.points;
    expect(points.length).toBe(2);
    // Primeiro ponto: 10 tokens × R$3,00 = R$30,00 (3000 centavos)
    expect(points[0].value).toBe(3000);
    expect(points[0].type).toBe("buy");
    // Segundo ponto: 15 tokens × R$4,00 = R$60,00 (6000 centavos)
    expect(points[1].value).toBe(6000);
    expect(points[1].type).toBe("buy");
  });

  it("deve diminuir patrimônio com vendas", async () => {
    // Compra 10 tokens a R$3,00, depois vende 5
    mockGetDocs.mockResolvedValue({
      empty: false,
      docs: [
        createTransactionDoc("buy", 300, 10, "startup-a", 30),   // 10 × 300 = 3000
        createTransactionDoc("sell", 300, 5, "startup-a", 15),   // 5 × 300 = 1500
      ],
    });

    const {getTokenHistory} = require("../../../exchange/handlers/getTokenHistory");

    const result = await getTokenHistory.run({
      data: {period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.points;
    expect(points.length).toBe(2);
    expect(points[0].value).toBe(3000);   // Após compra: 10 × 300
    expect(points[1].value).toBe(1500);   // Após venda: 5 × 300
    expect(points[1].type).toBe("sell");
  });

  it("deve ignorar transações de crédito", async () => {
    mockGetDocs.mockResolvedValue({
      empty: false,
      docs: [
        createTransactionDoc("credit", 0, 0, "", 30),            // Crédito — ignorado
        createTransactionDoc("buy", 500, 10, "startup-a", 15),   // 10 × 500 = 5000
      ],
    });

    const {getTokenHistory} = require("../../../exchange/handlers/getTokenHistory");

    const result = await getTokenHistory.run({
      data: {period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.points;
    // Só 1 ponto real + 1 ponto "início" adicionado automaticamente
    expect(points.length).toBe(2);
    expect(points[0].label).toBe("início");
    expect(points[1].value).toBe(5000);
  });

  it("deve calcular variação percentual corretamente", async () => {
    // Patrimônio vai de 2000 pra 3000 = +50%
    mockGetDocs.mockResolvedValue({
      empty: false,
      docs: [
        createTransactionDoc("buy", 200, 10, "startup-a", 30),   // 10 × 200 = 2000
        createTransactionDoc("buy", 300, 10, "startup-a", 15),   // 20 × 300 = 6000 (não 3000!)
      ],
    });

    const {getTokenHistory} = require("../../../exchange/handlers/getTokenHistory");

    const result = await getTokenHistory.run({
      data: {period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    // Variação: ((6000 - 2000) / 2000) × 100 = 200%
    expect(result.data.variation).toBe(200);
  });

  it("deve suportar múltiplas startups no patrimônio", async () => {
    mockGetDocs.mockResolvedValue({
      empty: false,
      docs: [
        createTransactionDoc("buy", 300, 10, "startup-a", 30),   // A: 10×300 = 3000
        createTransactionDoc("buy", 500, 5, "startup-b", 15),    // A: 3000 + B: 5×500 = 5500
      ],
    });

    const {getTokenHistory} = require("../../../exchange/handlers/getTokenHistory");

    const result = await getTokenHistory.run({
      data: {period: "dia"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.points;
    expect(points[0].value).toBe(3000);   // Só startup A
    expect(points[1].value).toBe(5500);   // Startup A + B
  });
});
