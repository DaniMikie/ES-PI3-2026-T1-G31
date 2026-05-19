/**
 * Testes: exchangeRepository — funções de tokens e transações
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

jest.mock("firebase-admin/app", () => ({
  getApps: jest.fn(() => [{}]),
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(() => ({})),
}));

const mockSet = jest.fn();
const mockGet = jest.fn();
const mockAdd = jest.fn();
const mockUpdate = jest.fn();
const mockDelete = jest.fn();

const mockInvestorDoc = jest.fn(() => ({
  set: mockSet,
  get: mockGet,
  update: mockUpdate,
  delete: mockDelete,
}));

const mockInvestorsCollection = jest.fn(() => ({
  doc: mockInvestorDoc,
}));

const mockStartupDoc = jest.fn(() => ({
  collection: mockInvestorsCollection,
  ref: {
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: mockGet,
      })),
    })),
  },
}));

const mockTransactionsCollection = jest.fn(() => ({
  add: mockAdd,
}));

const mockUserDoc = jest.fn(() => ({
  collection: mockTransactionsCollection,
  get: mockGet,
  update: mockUpdate,
}));

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collection: jest.fn((name: string) => {
      if (name === "startups") {
        return {doc: mockStartupDoc, get: jest.fn()};
      }
      return {doc: mockUserDoc};
    }),
  })),
  FieldValue: {
    increment: jest.fn((val: number) => `INCREMENT_${val}`),
    serverTimestamp: jest.fn(() => "MOCK_TIMESTAMP"),
  },
  Timestamp: {},
}));

import {
  addTokens,
  saveTransaction,
  getTokenPosition,
  removeTokens,
} from "../../../exchange/repositories/exchangeRepository";

describe("exchangeRepository — tokens e transações", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("addTokens", () => {
    it("deve criar/atualizar posição do investidor com merge", async () => {
      mockSet.mockResolvedValue(undefined);

      await addTokens("greenpulse", "user-123", 10, 2910);

      expect(mockStartupDoc).toHaveBeenCalledWith("greenpulse");
      expect(mockInvestorsCollection).toHaveBeenCalledWith("investors");
      expect(mockInvestorDoc).toHaveBeenCalledWith("user-123");
      expect(mockSet).toHaveBeenCalledWith(
        {
          quantity: "INCREMENT_10",
          totalInvestedCents: "INCREMENT_2910",
          updatedAt: "MOCK_TIMESTAMP",
        },
        {merge: true}
      );
    });
  });

  describe("saveTransaction", () => {
    it("deve salvar transação na subcoleção do usuário", async () => {
      mockAdd.mockResolvedValue({id: "tx-001"});

      const transaction = {
        type: "buy" as const,
        startupId: "greenpulse",
        startupName: "GreenPulse",
        quantity: 10,
        priceCents: 291,
        totalCents: 2910,
      };

      const id = await saveTransaction("user-123", transaction);

      expect(mockUserDoc).toHaveBeenCalledWith("user-123");
      expect(mockTransactionsCollection).toHaveBeenCalledWith("transactions");
      expect(mockAdd).toHaveBeenCalledWith({
        ...transaction,
        createdAt: "MOCK_TIMESTAMP",
      });
      expect(id).toBe("tx-001");
    });
  });

  describe("getTokenPosition", () => {
    it("deve retornar posição quando investidor existe", async () => {
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({quantity: 10, totalInvestedCents: 2910}),
      });

      const result = await getTokenPosition("greenpulse", "user-123");

      expect(result).toEqual({quantity: 10, totalInvestedCents: 2910});
    });

    it("deve retornar undefined quando não é investidor", async () => {
      mockGet.mockResolvedValue({exists: false});

      const result = await getTokenPosition("greenpulse", "user-456");

      expect(result).toBeUndefined();
    });
  });

  describe("removeTokens", () => {
    it("deve deletar documento quando vende todos os tokens", async () => {
      mockGet.mockResolvedValue({
        data: () => ({quantity: 5}),
      });
      mockDelete.mockResolvedValue(undefined);

      await removeTokens("greenpulse", "user-123", 5);

      expect(mockDelete).toHaveBeenCalled();
    });

    it("deve decrementar quando ainda sobra tokens", async () => {
      mockGet.mockResolvedValue({
        data: () => ({quantity: 10}),
      });
      mockUpdate.mockResolvedValue(undefined);

      await removeTokens("greenpulse", "user-123", 3);

      expect(mockUpdate).toHaveBeenCalledWith({
        quantity: "INCREMENT_-3",
        updatedAt: "MOCK_TIMESTAMP",
      });
    });
  });
});
