/**
 * Repository de Users — acesso ao Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Funções que leem/escrevem dados de usuários na coleção users/{uid}.
 */

import {FieldValue} from "firebase-admin/firestore";
import {UserDocument} from "../types";
import {db} from "../../startups/shared/firebase";

const usersCollection = db.collection("users");

/**
 * Cria o perfil do usuário no Firestore.
 * Chamada após o cadastro no Firebase Auth.
 * Salva nome, email, CPF, telefone e timestamp de criação.
 */
export async function createUserProfile(
  uid: string,
  data: UserDocument
): Promise<void> {
  await usersCollection.doc(uid).set({
    ...data,
    createdAt: FieldValue.serverTimestamp(),
  });
}

/**
 * Busca o perfil do usuário pelo uid.
 * Retorna undefined se o documento não existir.
 */
export async function getUserProfile(
  uid: string
): Promise<UserDocument | undefined> {
  const snapshot = await usersCollection.doc(uid).get();
  if (!snapshot.exists) {
    return undefined;
  }
  return snapshot.data() as UserDocument;
}
