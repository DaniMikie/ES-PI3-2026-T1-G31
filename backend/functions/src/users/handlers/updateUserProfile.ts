/**
 * Handler: updateUserProfile — atualiza dados do perfil do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {db} from "../../startups/shared/firebase";

export const updateUserProfile = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const name = normalizeString(request.data?.name);
  const phone = normalizeString(request.data?.phone);

  const updates: Record<string, string> = {};
  if (name) updates.name = name;
  if (phone) updates.phone = phone;

  if (Object.keys(updates).length === 0) {
    return {data: {message: "Nenhum dado para atualizar."}};
  }

  await db.collection("users").doc(user.uid).set(updates, {merge: true});

  return {
    data: {
      uid: user.uid,
      ...updates,
    },
  };
});
