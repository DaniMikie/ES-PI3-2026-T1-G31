/*Handler: withdrawCredits — permite o usuário retirar saldo fictício da carteira
Autor: Ana Luísa Maso Mafra | RA: 25007997
*/

/*
O Flutter chama essa function quando o usuário confirma o saque.
Valida saldo suficiente, subtrai do balanceCents e retorna o novo saldo.
A senha é verificada via Firebase Auth (reautenticação feita no client).
*/

import { HttpsError, onCall } from "firebase-functions/https";
import { requireAuthenticatedUser } from "../../startups/shared/auth";
import { db } from "../../startups/shared/firebase";
import { FieldValue } from "firebase-admin/firestore";

export const withdrawCredits = onCall(async (request) => {
  // 1. Verifica login
  const user = requireAuthenticatedUser(request);

  // 2. Pega o valor a sacar (em centavos)
  const amount = request.data?.amount;

  // 3. Valida: amount deve ser número inteiro positivo
  if (typeof amount !== "number" || !Number.isInteger(amount) || amount <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Informe um valor válido para saque (em centavos, inteiro positivo)."
    );
  }

  // 4. Busca o documento do usuário no Firestore
  const userRef = db.collection("users").doc(user.uid);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  const userData = userSnap.data()!;
  const currentBalance: number = typeof userData.balanceCents === "number"
    ? userData.balanceCents
    : 0;

  // 5. Valida saldo suficiente
  if (currentBalance < amount) {
    throw new HttpsError(
      "failed-precondition",
      "Saldo insuficiente para realizar o saque."
    );
  }

  // 6. Subtrai do saldo usando transação atômica (evita race condition)
  const newBalance = await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(userRef);
    const balance: number = typeof snap.data()?.balanceCents === "number"
      ? snap.data()!.balanceCents
      : 0;

    if (balance < amount) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente para realizar o saque."
      );
    }

    const updated = balance - amount;

    // Atualiza o saldo
    transaction.update(userRef, { balanceCents: updated });

    // Registra a transação no histórico do usuário
    // Correção: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
    // Alterado de db.collection("transactions") para subcoleção users/{uid}/transactions
    // para que o listTransactions encontre o registro corretamente.
    const txRef = db.collection("users").doc(user.uid).collection("transactions").doc();
    transaction.set(txRef, {
      type: "withdrawal",
      startupId: "",
      startupName: "",
      quantity: 0,
      priceCents: 0,
      totalCents: amount,
      createdAt: FieldValue.serverTimestamp(),
    });

    return updated;
  });

  // 7. Retorna novo saldo pro Flutter
  return {
    data: {
      uid: user.uid,
      balanceCents: newBalance,
    },
  };
});
