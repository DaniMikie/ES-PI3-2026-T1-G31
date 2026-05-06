/**
 * Testes: userRepository — acesso ao Firestore (mock)
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
const mockDoc = jest.fn(() => ({
  set: mockSet,
  get: mockGet,
}));

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: mockDoc,
    })),
  })),
  FieldValue: {
    serverTimestamp: jest.fn(() => "MOCK_TIMESTAMP"),
  },
  Timestamp: {},
}));

import {createUserProfile, getUserProfile} from "../../../startups/repositories/userRepository";

describe("userRepository", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("createUserProfile", () => {
    it("deve salvar perfil do usuário no Firestore", async () => {
      mockSet.mockResolvedValue(undefined);

      await createUserProfile("user-123", {
        name: "Daniela",
        email: "dani@email.com",
        cpf: "123.456.789-00",
        phone: "(19) 99999-9999",
      });

      expect(mockDoc).toHaveBeenCalledWith("user-123");
      expect(mockSet).toHaveBeenCalledWith({
        name: "Daniela",
        email: "dani@email.com",
        cpf: "123.456.789-00",
        phone: "(19) 99999-9999",
        createdAt: "MOCK_TIMESTAMP",
      });
    });
  });

  describe("getUserProfile", () => {
    it("deve retornar perfil quando existe", async () => {
      mockGet.mockResolvedValue({
        exists: true,
        data: () => ({
          name: "Daniela",
          email: "dani@email.com",
          cpf: "123.456.789-00",
          phone: "(19) 99999-9999",
        }),
      });

      const result = await getUserProfile("user-123");
      expect(result).toBeDefined();
      expect(result?.name).toBe("Daniela");
      expect(result?.cpf).toBe("123.456.789-00");
    });

    it("deve retornar undefined quando não existe", async () => {
      mockGet.mockResolvedValue({exists: false});

      const result = await getUserProfile("user-inexistente");
      expect(result).toBeUndefined();
    });
  });
});
