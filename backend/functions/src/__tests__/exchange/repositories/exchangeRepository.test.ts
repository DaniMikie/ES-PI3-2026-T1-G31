/**
 * Testes: exchangeRepository — acesso ao Firestore (mock)
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

jest.mock("firebase-admin/app", () => ({
  getApps: jest.fn(() => [{}]),
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(() => ({})),
}));

const mockGet = jest.fn();
const mockUpdate = jest.fn();
const mockDoc = jest.fn(() => ({
  get: mockGet,
  update: mockUpdate,
}));

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: mockDoc,
    })),
  })),
  FieldValue: {
    increment: jest.fn((val: number) => `INCREMENT_${val}`),
    serverTimestamp: jest.fn(() => "MOCK_TIMESTAMP"),
  },
  Timestamp: {},
}));

import {getBalance, updateBalance} from "../../../exchange/repositories/exchangeRepository";

describe("exchangeRepository", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("getBalance", () => {
    it("deve retornar balanceCents quando o campo existe", async () => {
      mockGet.mockResolvedValue({
        data: () => ({balanceCents: 15000}),
      });

      const result = await getBalance("user-123");

      expect(mockDoc).toHaveBeenCalledWith("user-123");
      expect(result).toBe(15000);
    });

    it("deve retornar 0 quando balanceCents não existe", async () => {
      mockGet.mockResolvedValue({
        data: () => ({name: "Daniela", email: "dani@email.com"}),
      });

      const result = await getBalance("user-456");
      expect(result).toBe(0);
    });

    it("deve retornar 0 quando o documento não tem dados", async () => {
      mockGet.mockResolvedValue({
        data: () => undefined,
      });

      const result = await getBalance("user-789");
      expect(result).toBe(0);
    });
  });

  describe("updateBalance", () => {
    it("deve chamar update com FieldValue.increment positivo", async () => {
      mockUpdate.mockResolvedValue(undefined);

      await updateBalance("user-123", 10000);

      expect(mockDoc).toHaveBeenCalledWith("user-123");
      expect(mockUpdate).toHaveBeenCalledWith({
        balanceCents: "INCREMENT_10000",
      });
    });

    it("deve chamar update com FieldValue.increment negativo", async () => {
      mockUpdate.mockResolvedValue(undefined);

      await updateBalance("user-123", -2910);

      expect(mockDoc).toHaveBeenCalledWith("user-123");
      expect(mockUpdate).toHaveBeenCalledWith({
        balanceCents: "INCREMENT_-2910",
      });
    });
  });
});
