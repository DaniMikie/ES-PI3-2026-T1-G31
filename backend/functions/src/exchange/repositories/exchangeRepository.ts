/**
 * Repository de exchange — acesso ao Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {TransactionDocument} from "../types";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../startups/shared/firebase";

export async function getBalance(uid: string): Promise<number> {
    const exchangeSnapshot = await db.collection("users").doc(uid).get();
    const data = exchangeSnapshot.data();

    return data?.balanceCents ?? 0;
}

export async function updateBalance(uid: string, amountCents: number): Promise<void> {
    await db.collection("users").doc(uid).update({
        balanceCents: FieldValue.increment(amountCents),
    });
}

export async function addTokens(startupId: string, uid: string, quantity: number, totalCents: number): Promise<void> {
    await db.collection("startups").doc(startupId).collection("investors").doc(uid).set({
        quantity: FieldValue.increment(quantity),
        totalInvestedCents: FieldValue.increment(totalCents),
        updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true}); //se o documento já existe, soma os valores. Se não existe, cria com esses valores
}

export async function saveTransaction(uid: string, transaction: TransactionDocument): Promise<string> {
    const ref = await db.collection("users").doc(uid).collection("transactions").add({
        ...transaction,
        createdAt: FieldValue.serverTimestamp(),
    });
    return ref.id;
}

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
