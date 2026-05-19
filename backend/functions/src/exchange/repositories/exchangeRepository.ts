/**
 * Repository de exchange — acesso ao Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Este arquivo contém todas as funções que leem/escrevem dados
 * relacionados à carteira e tokens no Firestore.
 * Nenhum handler acessa o banco direto — todos passam por aqui.
 */

import {TransactionDocument} from "../types";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../startups/shared/firebase";

/**
 * Busca o saldo atual da carteira do usuário.
 * Lê o campo balanceCents do documento users/{uid}.
 * Retorna 0 se o campo ainda não existir.
 */
export async function getBalance(uid: string): Promise<number> {
  const exchangeSnapshot = await db.collection("users").doc(uid).get();
  const data = exchangeSnapshot.data();
  return data?.balanceCents ?? 0;
}

/**
 * Soma ou subtrai valor do saldo do usuário.
 * Usa FieldValue.increment que é atômico (seguro pra concorrência).
 * Valor positivo = deposita. Valor negativo = desconta.
 */
export async function updateBalance(uid: string, amountCents: number): Promise<void> {
  await db.collection("users").doc(uid).update({
    balanceCents: FieldValue.increment(amountCents),
  });
}

/**
 * Registra tokens comprados pelo usuário em uma startup.
 * Cria/atualiza o documento em startups/{startupId}/investors/{uid}.
 * O {merge: true} faz com que: se já existe, soma. Se não existe, cria.
 * Ao criar esse documento, o usuário automaticamente vira investidor.
 */
export async function addTokens(startupId: string, uid: string, quantity: number, totalCents: number): Promise<void> {
  await db.collection("startups").doc(startupId).collection("investors").doc(uid).set({
    quantity: FieldValue.increment(quantity),
    totalInvestedCents: FieldValue.increment(totalCents),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

/**
 * Salva o registro de uma transação (compra ou venda) no histórico do usuário.
 * Cria documento em users/{uid}/transactions com ID automático.
 * Retorna o ID do documento criado.
 */
export async function saveTransaction(uid: string, transaction: TransactionDocument): Promise<string> {
  const ref = await db.collection("users").doc(uid).collection("transactions").add({
    ...transaction,
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

/**
 * Busca o histórico de transações do usuário.
 * Lê users/{uid}/transactions e ordena por data mais recente primeiro.
 */
export async function getTransactions(uid: string): Promise<TransactionDocument[]> {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection("transactions")
    .orderBy("createdAt", "desc")
    .get();

  return snapshot.docs.map((doc) => doc.data() as TransactionDocument);
}

/**
 * Busca a posição de tokens do usuário em uma startup específica.
 * Lê startups/{startupId}/investors/{uid}.
 * Retorna undefined se o usuário não for investidor daquela startup.
 */
export async function getTokenPosition(
  startupId: string,
  uid: string
): Promise<{quantity: number; totalInvestedCents: number} | undefined> {
  const snapshot = await db
    .collection("startups")
    .doc(startupId)
    .collection("investors")
    .doc(uid)
    .get();

  if (!snapshot.exists) {
    return undefined;
  }

  const data = snapshot.data();
  return {
    quantity: data?.quantity ?? 0,
    totalInvestedCents: data?.totalInvestedCents ?? 0,
  };
}

/**
 * Remove tokens vendidos pelo usuário.
 * Se a quantidade restante for 0 ou menos, deleta o documento
 * (o usuário deixa de ser investidor daquela startup).
 * Se ainda sobrar tokens, apenas decrementa a quantidade.
 */
export async function removeTokens(
  startupId: string,
  uid: string,
  quantity: number
): Promise<void> {
  const investorRef = db
    .collection("startups")
    .doc(startupId)
    .collection("investors")
    .doc(uid);

  const snapshot = await investorRef.get();
  const currentQuantity = snapshot.data()?.quantity ?? 0;

  if (currentQuantity - quantity <= 0) {
    // Vendeu tudo — remove o documento (deixa de ser investidor)
    await investorRef.delete();
  } else {
    // Ainda tem tokens — atualiza a quantidade
    await investorRef.update({
      quantity: FieldValue.increment(-quantity),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

/**
 * Busca todas as posições de tokens do usuário em todas as startups.
 * Percorre cada startup e verifica se o usuário é investidor.
 * Retorna array com startupId, quantidade e valor investido.
 */
export async function getUserTokenPositions(
  uid: string
): Promise<Array<{startupId: string; quantity: number; totalInvestedCents: number}>> {
  const startupsSnapshot = await db.collection("startups").get();
  const positions: Array<{startupId: string; quantity: number; totalInvestedCents: number}> = [];

  for (const startupDoc of startupsSnapshot.docs) {
    const investorSnapshot = await startupDoc.ref
      .collection("investors")
      .doc(uid)
      .get();

    if (investorSnapshot.exists) {
      const data = investorSnapshot.data();
      positions.push({
        startupId: startupDoc.id,
        quantity: data?.quantity ?? 0,
        totalInvestedCents: data?.totalInvestedCents ?? 0,
      });
    }
  }

  return positions;
}
