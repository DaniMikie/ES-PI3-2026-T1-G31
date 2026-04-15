/**
 * Verificação de autenticação — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {CallableRequest, HttpsError} from "firebase-functions/https";
import {AuthenticatedUser} from "../types";

export function requireAuthenticatedUser(
  request: CallableRequest
): AuthenticatedUser {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuario precisa estar autenticado para acessar esta funcao."
    );
  }
  return {
    uid: request.auth.uid,
    email: request.auth.token.email as string | undefined,
  };
}
