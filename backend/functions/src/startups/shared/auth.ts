/**
 * Verificação de autenticação — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Função reutilizável que verifica se o usuário está logado.
 * Todos os handlers chamam essa função no início.
 * Se não estiver logado, lança erro e a function para.
 * Se estiver, retorna uid e email do usuário.
 */

import {CallableRequest, HttpsError} from "firebase-functions/https";
import {AuthenticatedUser} from "../types";

export function requireAuthenticatedUser(
  request: CallableRequest
): AuthenticatedUser {
  // request.auth é preenchido automaticamente pelo Firebase quando o Flutter
  // manda o token de login junto com a chamada
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
