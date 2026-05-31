/**
 * Testes: getPortfolioHistory — gráfico de variação do portfólio
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Testa o cálculo de variação % por startup:
 * - Ponto base (0%) é adicionado no início
 * - Ponto atual é adicionado no final
 * - Variação = ((preço atual - preço médio compra) / preço médio) × 100
 * - Retorna quantity e currentPriceCents pra cálculo de lucro
 */

jest.mock("firebase-admin/app", () => ({
  getApps: jest.fn(() => [{}]),
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(() => ({})),
}));

const mockPriceHistoryGet = jest.fn();
const mockPortfolioStartupDocGet = jest.fn();

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: mockPortfolioStartupDocGet,
        collection: jest.fn(() => ({
          where: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: mockPriceHistoryGet,
        })),
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

// Mock do getUserTokenPositions
const mockGetUserTokenPositions = jest.fn();
jest.mock("../../../exchange/repositories/exchangeRepository", () => ({
  getUserTokenPositions: mockGetUserTokenPositions,
}));

describe("getPortfolioHistory — variação por startup", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockPortfolioStartupDocGet.mockResolvedValue({
      data: () => ({name: "AgroSmart", currentTokenPriceCents: 289}),
    });
    mockPriceHistoryGet.mockResolvedValue({docs: []});
  });

  it("deve retornar lines vazio quando usuário não tem investimentos", async () => {
    mockGetUserTokenPositions.mockResolvedValue([]);

    const {getPortfolioHistory} = require("../../../exchange/handlers/getPortfolioHistory");

    const result = await getPortfolioHistory.run({
      data: {period: "mes"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    expect(result.data.lines).toEqual([]);
  });

  it("deve retornar dados corretos pra uma startup", async () => {
    // Usuário tem 300 tokens da AgroSmart, investiu R$12,95 (1295 centavos) no total
    mockGetUserTokenPositions.mockResolvedValue([
      {startupId: "agrosmart", quantity: 300, totalInvestedCents: 129500, currentTokenPriceCents: 289},
    ]);

    const {getPortfolioHistory} = require("../../../exchange/handlers/getPortfolioHistory");

    const result = await getPortfolioHistory.run({
      data: {period: "mes"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const lines = result.data.lines;
    expect(lines.length).toBe(1);

    const line = lines[0];
    expect(line.startupId).toBe("agrosmart");
    expect(line.startupName).toBe("AgroSmart");
    expect(line.quantity).toBe(300);
    expect(line.currentPriceCents).toBe(289);
    // Preço médio: 129500 / 300 ≈ 431.67
    expect(line.avgBuyCents).toBe(Math.round(129500 / 300));
  });

  it("deve incluir ponto base (0%) e ponto atual", async () => {
    mockGetUserTokenPositions.mockResolvedValue([
      {startupId: "agrosmart", quantity: 100, totalInvestedCents: 30000, currentTokenPriceCents: 289},
    ]);

    const {getPortfolioHistory} = require("../../../exchange/handlers/getPortfolioHistory");

    const result = await getPortfolioHistory.run({
      data: {period: "mes"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.lines[0].points;
    // Primeiro ponto deve ser 0% (ponto base)
    expect(points[0].variation).toBe(0);
    // Último ponto deve ter a variação atual
    const lastPoint = points[points.length - 1];
    expect(lastPoint.timestamp).toBe("agora");
    // Variação: ((289 - 300) / 300) × 100 = -3.67%
    expect(lastPoint.variation).toBeLessThan(0);
  });

  it("deve calcular variação positiva quando preço subiu", async () => {
    // Comprou a R$3,00 (300 centavos), agora vale R$4,00 (400 centavos)
    mockGetUserTokenPositions.mockResolvedValue([
      {startupId: "greenpulse", quantity: 100, totalInvestedCents: 30000, currentTokenPriceCents: 400},
    ]);
    mockPortfolioStartupDocGet.mockResolvedValue({
      data: () => ({name: "GreenPulse", currentTokenPriceCents: 400}),
    });

    const {getPortfolioHistory} = require("../../../exchange/handlers/getPortfolioHistory");

    const result = await getPortfolioHistory.run({
      data: {period: "mes"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const lastPoint = result.data.lines[0].points.slice(-1)[0];
    // Variação: ((400 - 300) / 300) × 100 = +33.33%
    expect(lastPoint.variation).toBeGreaterThan(0);
    expect(lastPoint.variation).toBeCloseTo(33.33, 0);
  });

  it("deve atribuir cores diferentes pra cada startup", async () => {
    mockGetUserTokenPositions.mockResolvedValue([
      {startupId: "agrosmart", quantity: 100, totalInvestedCents: 30000, currentTokenPriceCents: 289},
      {startupId: "eduflex", quantity: 200, totalInvestedCents: 50000, currentTokenPriceCents: 310},
    ]);
    mockPortfolioStartupDocGet.mockResolvedValue({
      data: () => ({name: "Startup", currentTokenPriceCents: 300}),
    });

    const {getPortfolioHistory} = require("../../../exchange/handlers/getPortfolioHistory");

    const result = await getPortfolioHistory.run({
      data: {period: "mes"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const lines = result.data.lines;
    expect(lines.length).toBe(2);
    // Cores devem ser diferentes
    expect(lines[0].color).not.toBe(lines[1].color);
  });

  it("deve incluir pontos do priceHistory quando existem", async () => {
    mockGetUserTokenPositions.mockResolvedValue([
      {startupId: "agrosmart", quantity: 100, totalInvestedCents: 30000, currentTokenPriceCents: 350},
    ]);
    mockPortfolioStartupDocGet.mockResolvedValue({
      data: () => ({name: "AgroSmart", currentTokenPriceCents: 350}),
    });

    // Simula 2 registros no priceHistory
    const date1 = new Date();
    date1.setDate(date1.getDate() - 10);
    const date2 = new Date();
    date2.setDate(date2.getDate() - 5);

    mockPriceHistoryGet.mockResolvedValue({
      docs: [
        {data: () => ({price: 280, createdAt: {toDate: () => date1}})},
        {data: () => ({price: 320, createdAt: {toDate: () => date2}})},
      ],
    });

    const {getPortfolioHistory} = require("../../../exchange/handlers/getPortfolioHistory");

    const result = await getPortfolioHistory.run({
      data: {period: "mes"},
      auth: {uid: "user-123", token: {email: "dani@test.com"}},
    });

    const points = result.data.lines[0].points;
    // Deve ter: ponto base (0%) + 2 do priceHistory + ponto atual = 4 pontos
    expect(points.length).toBe(4);
    expect(points[0].variation).toBe(0);  // Base
    // Ponto do priceHistory: ((280 - 300) / 300) × 100 = -6.67%
    expect(points[1].variation).toBeLessThan(0);
  });
});
