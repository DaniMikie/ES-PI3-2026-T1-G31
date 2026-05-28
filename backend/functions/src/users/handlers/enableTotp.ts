/**
 * Handler: enableTotp — gera secret TOTP para o usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Gera um secret TOTP, salva no Firestore e retorna a URI
 * para o usuário escanear no Google Authenticator.
 */

import {onCall} from "firebase-functions/https";
import {authenticator} from "otplib";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const enableTotp = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  // Gera um secret aleatório
  const secret = authenticator.generateSecret();

  // Monta a URI otpauth (que o Google Authenticator lê do QR code)
  const otpauthUrl = authenticator.keyuri(
    user.email ?? user.uid,
    "MesclaInvest",
    secret
  );

  // Salva o secret no documento do usuário (não ativa ainda — precisa verificar)
  await db.collection("users").doc(user.uid).set(
    {totpSecret: secret, totpEnabled: false},
    {merge: true}
  );

  return {
    data: {
      secret,
      otpauthUrl,
    },
  };
});
