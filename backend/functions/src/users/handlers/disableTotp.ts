/**
 * Handler: disableTotp — desativa TOTP do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {authenticator} from "otplib";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {db} from "../../startups/shared/firebase";

export const disableTotp = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  // Exige código válido pra desativar (segurança)
  const code = normalizeString(request.data?.code);
  if (!code || code.length !== 6) {
    throw new HttpsError("invalid-argument", "Informe o codigo de 6 digitos para desativar.");
  }

  const userDoc = await db.collection("users").doc(user.uid).get();
  const totpSecret = userDoc.data()?.totpSecret as string | undefined;

  if (!totpSecret) {
    throw new HttpsError("failed-precondition", "TOTP nao esta ativo.");
  }

  const isValid = authenticator.verify({token: code, secret: totpSecret});
  if (!isValid) {
    throw new HttpsError("permission-denied", "Codigo invalido.");
  }

  // Remove secret e desativa
  await db.collection("users").doc(user.uid).set(
    {totpSecret: null, totpEnabled: false, mfaAtivo: false},
    {merge: true}
  );

  return {data: {disabled: true}};
});
