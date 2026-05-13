/**
 * Handler: updateMfaPreference — atualiza preferência de MFA do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o usuário liga/desliga o toggle de MFA.
 * Salva a preferência no documento do usuário no Firestore.
 * A implementação real do MFA (segundo fator) é feita separadamente.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const updateMfaPreference = onCall(async (request) => {
  // 1. Verifica login
  const user = requireAuthenticatedUser(request);

  // 2. Pega a preferência (true = ativado, false = desativado)
  const mfaAtivo = request.data?.mfaAtivo === true;

  // 3. Salva no documento do usuário (merge: true não apaga outros campos)
  await db.collection("users").doc(user.uid).set(
    {mfaAtivo},
    {merge: true}
  );

  // 4. Retorna confirmação
  return {
    data: {
      uid: user.uid,
      mfaAtivo,
    },
  };
});
