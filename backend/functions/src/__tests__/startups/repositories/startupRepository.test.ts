/**
 * Testes: startupRepository — acesso ao Firestore (mock)
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

// Mock do firebase-admin antes de importar o repository
jest.mock("firebase-admin/app", () => ({
  getApps: jest.fn(() => [{}]),
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(() => ({})),
}));

const mockGet = jest.fn();
const mockAdd = jest.fn();
const mockDoc = jest.fn();
const mockSet = jest.fn();
const mockCommit = jest.fn();
const mockWhere = jest.fn();
const mockLimit = jest.fn();

const mockCollection = jest.fn(() => ({
  limit: mockLimit,
  doc: mockDoc,
  add: mockAdd,
  where: mockWhere,
}));

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collection: mockCollection,
    batch: jest.fn(() => ({
      set: mockSet,
      commit: mockCommit,
    })),
  })),
  FieldValue: {
    serverTimestamp: jest.fn(() => "MOCK_TIMESTAMP"),
  },
  Timestamp: {},
}));

import {
  listStartupItems,
  getStartupById,
  seedDemoStartups,
} from "../../../startups/repositories/startupRepository";

describe("startupRepository", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("listStartupItems", () => {
    it("deve retornar lista de startups do Firestore", async () => {
      const mockDocs = [
        {
          id: "greenpulse",
          data: () => ({
            name: "GreenPulse",
            stage: "em_operacao",
            shortDescription: "Plataforma de energia",
            capitalRaisedCents: 32000000,
            totalTokensIssued: 110000,
            currentTokenPriceCents: 291,
            tags: ["cleantech"],
          }),
        },
      ];

      mockLimit.mockReturnValue({get: mockGet});
      mockGet.mockResolvedValue({docs: mockDocs});

      const result = await listStartupItems();

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe("greenpulse");
      expect(result[0].name).toBe("GreenPulse");
    });

    it("deve retornar lista vazia quando não há startups", async () => {
      mockLimit.mockReturnValue({get: mockGet});
      mockGet.mockResolvedValue({docs: []});

      const result = await listStartupItems();
      expect(result).toHaveLength(0);
    });
  });

  describe("getStartupById", () => {
    it("deve retornar startup quando existe", async () => {
      const mockSnapshot = {
        exists: true,
        data: () => ({
          name: "GreenPulse",
          stage: "em_operacao",
        }),
      };

      mockDoc.mockReturnValue({get: jest.fn().mockResolvedValue(mockSnapshot)});

      const result = await getStartupById("greenpulse");
      expect(result).toBeDefined();
      expect(result?.name).toBe("GreenPulse");
    });

    it("deve retornar undefined quando startup não existe", async () => {
      const mockSnapshot = {exists: false};
      mockDoc.mockReturnValue({get: jest.fn().mockResolvedValue(mockSnapshot)});

      const result = await getStartupById("inexistente");
      expect(result).toBeUndefined();
    });
  });

  describe("seedDemoStartups", () => {
    it("deve criar 5 startups demo e retornar seus IDs", async () => {
      mockDoc.mockReturnValue({});
      mockCommit.mockResolvedValue(undefined);

      const ids = await seedDemoStartups();

      expect(ids).toHaveLength(5);
      expect(ids).toContain("greenpulse");
      expect(ids).toContain("medconnect");
      expect(ids).toContain("agrosmart");
      expect(ids).toContain("eduflex");
      expect(ids).toContain("fintoken");
    });
  });
});
