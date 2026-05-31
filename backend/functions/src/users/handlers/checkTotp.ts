/**
 * Handler: checkTotp — verifica se o usuário tem TOTP ativo
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Chamado após login com email/senha pra saber se precisa pedir código.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const checkTotp = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const userDoc = await db.collection("users").doc(user.uid).get();
  const totpEnabled = userDoc.data()?.totpEnabled === true;

  return {
    data: {
      totpEnabled,
    },
  };
});
