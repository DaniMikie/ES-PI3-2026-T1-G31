/**
 * Handler: createUser — salva dados do usuário no Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function logo após criar conta no Firebase Auth.
 * Salva os dados extras (nome, CPF, telefone) que o Auth não guarda.
 * Bloqueia se o perfil já existir (evita duplicação).
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {createUserProfile, getUserProfile} from "../repositories/userRepository";
import {UserDocument} from "../types";
import {db} from "../../startups/shared/firebase";

export const createUser = onCall(async (request) => {
  // 1. Verifica login (o usuário acabou de criar conta no Auth)
  const user = requireAuthenticatedUser(request);

  // 2. Pega dados que o Flutter mandou
  const name = normalizeString(request.data?.name);
  const cpf = normalizeString(request.data?.cpf);
  const phone = normalizeString(request.data?.phone);

  // 3. Valida: todos os campos são obrigatórios
  if (!name || !cpf || !phone) {
    throw new HttpsError(
      "invalid-argument",
      "Informe name, cpf e phone."
    );
  }

  // 4. Verifica se já existe perfil (evita criar duplicado)
  const existing = await getUserProfile(user.uid);
  if (existing) {
    throw new HttpsError(
      "already-exists",
      "Perfil de usuario ja existe."
    );
  }

  // 4.1 Verifica se CPF já está cadastrado por outro usuário
  const cpfCheck = await db.collection("users")
    .where("cpf", "==", cpf)
    .limit(1)
    .get();
  if (!cpfCheck.empty) {
    throw new HttpsError(
      "already-exists",
      "Este CPF ja esta cadastrado."
    );
  }

  // 5. Monta o documento do usuário
  const userDoc: UserDocument = {
    name,
    email: user.email ?? "",
    cpf,
    phone,
  };

  // 6. Salva no Firestore em users/{uid}
  await createUserProfile(user.uid, userDoc);

  // 7. Retorna confirmação pro Flutter
  return {
    data: {
      uid: user.uid,
      name,
      email: user.email,
    },
  };
});
