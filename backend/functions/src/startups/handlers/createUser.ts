/**
 * Handler: createUser — salva dados do usuário no Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {createUserProfile, getUserProfile} from "../repositories/userRepository";
import {UserDocument} from "../types";

export const createUser = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const name = normalizeString(request.data?.name);
  const cpf = normalizeString(request.data?.cpf);
  const phone = normalizeString(request.data?.phone);

  if (!name || !cpf || !phone) {
    throw new HttpsError(
      "invalid-argument",
      "Informe name, cpf e phone."
    );
  }

  // Verifica se já existe perfil
  const existing = await getUserProfile(user.uid);
  if (existing) {
    throw new HttpsError(
      "already-exists",
      "Perfil de usuario ja existe."
    );
  }

  const userDoc: UserDocument = {
    name,
    email: user.email ?? "",
    cpf,
    phone,
  };

  await createUserProfile(user.uid, userDoc);

  return {
    data: {
      uid: user.uid,
      name,
      email: user.email,
    },
  };
});
