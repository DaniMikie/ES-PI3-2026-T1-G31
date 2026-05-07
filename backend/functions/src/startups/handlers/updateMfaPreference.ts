/**
 * Handler: updateMfaPreference — atualiza preferência de MFA do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../shared/auth";
import {db} from "../shared/firebase";

export const updateMfaPreference = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const mfaAtivo = request.data?.mfaAtivo === true;

  await db.collection("users").doc(user.uid).set(
    {mfaAtivo},
    {merge: true}
  );

  return {
    data: {
      uid: user.uid,
      mfaAtivo,
    },
  };
});
