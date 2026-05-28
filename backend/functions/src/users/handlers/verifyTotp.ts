/**
 * Handler: verifyTotp — valida código TOTP e ativa MFA
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Recebe o código de 6 dígitos do Google Authenticator,
 * valida contra o secret salvo, e ativa o TOTP se correto.
 * Também usado no login pra verificar o segundo fator.
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {authenticator} from "otplib";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {db} from "../../startups/shared/firebase";

export const verifyTotp = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const code = normalizeString(request.data?.code);
  const action = normalizeString(request.data?.action) ?? "activate";

  if (!code || code.length !== 6) {
    throw new HttpsError("invalid-argument", "Informe o codigo de 6 digitos.");
  }

  // Busca o secret do usuário
  const userDoc = await db.collection("users").doc(user.uid).get();
  const totpSecret = userDoc.data()?.totpSecret as string | undefined;

  if (!totpSecret) {
    throw new HttpsError("failed-precondition", "TOTP nao configurado. Ative primeiro.");
  }

  // Valida o código
  const isValid = authenticator.verify({token: code, secret: totpSecret});

  if (!isValid) {
    throw new HttpsError("permission-denied", "Codigo invalido.");
  }

  // Se é ativação, marca como ativo
  if (action === "activate") {
    await db.collection("users").doc(user.uid).set(
      {totpEnabled: true, mfaAtivo: true},
      {merge: true}
    );
  }

  return {
    data: {
      valid: true,
      action,
    },
  };
});
