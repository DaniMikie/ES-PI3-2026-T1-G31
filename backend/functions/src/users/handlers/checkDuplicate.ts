/**
 * Handler: checkDuplicate — verifica se e-mail, CPF ou telefone já existem
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Chamado em tempo real enquanto o usuário preenche o cadastro.
 * Retorna quais campos já estão cadastrados por outro usuário.
 * Não exige autenticação (o usuário ainda não tem conta).
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {db} from "../../startups/shared/firebase";

export const checkDuplicate = onCall(async (request) => {
  const email = (request.data?.email as string ?? "").trim().toLowerCase();
  const cpf = (request.data?.cpf as string ?? "").trim();
  const phone = (request.data?.phone as string ?? "").trim();

  if (!email && !cpf && !phone) {
    throw new HttpsError("invalid-argument", "Informe pelo menos um campo.");
  }

  const result: {emailExists: boolean; cpfExists: boolean; phoneExists: boolean} = {
    emailExists: false,
    cpfExists: false,
    phoneExists: false,
  };

  // Verifica e-mail
  if (email) {
    const snap = await db.collection("users").where("email", "==", email).limit(1).get();
    result.emailExists = !snap.empty;
  }

  // Verifica CPF
  if (cpf) {
    const snap = await db.collection("users").where("cpf", "==", cpf).limit(1).get();
    result.cpfExists = !snap.empty;
  }

  // Verifica telefone
  if (phone) {
    const snap = await db.collection("users").where("phone", "==", phone).limit(1).get();
    result.phoneExists = !snap.empty;
  }

  return {data: result};
});
