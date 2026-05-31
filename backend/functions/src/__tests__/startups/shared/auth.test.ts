/**
 * Testes: requireAuthenticatedUser — verificação de autenticação
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {requireAuthenticatedUser} from "../../../startups/shared/auth";
import {CallableRequest} from "firebase-functions/https";

describe("requireAuthenticatedUser", () => {
  it("deve lançar erro se request.auth for undefined", () => {
    const fakeRequest = {auth: undefined} as CallableRequest;
    expect(() => requireAuthenticatedUser(fakeRequest)).toThrow(
      "Usuario precisa estar autenticado para acessar esta funcao."
    );
  });

  it("deve retornar uid e email quando autenticado", () => {
    const fakeRequest = {
      auth: {
        uid: "user-123",
        token: {email: "teste@email.com"},
      },
    } as unknown as CallableRequest;

    const result = requireAuthenticatedUser(fakeRequest);
    expect(result.uid).toBe("user-123");
    expect(result.email).toBe("teste@email.com");
  });

  it("deve retornar email undefined se token não tiver email", () => {
    const fakeRequest = {
      auth: {
        uid: "user-456",
        token: {},
      },
    } as unknown as CallableRequest;

    const result = requireAuthenticatedUser(fakeRequest);
    expect(result.uid).toBe("user-456");
    expect(result.email).toBeUndefined();
  });
});
