/**
 * Handler: sellTokens — venda simulada de tokens
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {
  getTokenPosition,
  updateBalance,
  removeTokens,
  saveTransaction,
} from "../repositories/exchangeRepository";
import {TransactionDocument} from "../types";

export const sellTokens = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const startupId = normalizeString(request.data?.startupId);
  const quantity = request.data?.quantity;

  if (!startupId) {
    throw new HttpsError("invalid-argument", "Informe o startupId.");
  }
  if (typeof quantity !== "number" || quantity <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Informe uma quantidade valida maior que zero."
    );
  }

  // Verificar se a startup existe
  const startup = await getStartupById(startupId);
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  // Verificar se o usuário tem tokens suficientes
  const position = await getTokenPosition(startupId, user.uid);
  if (!position || position.quantity < quantity) {
    throw new HttpsError(
      "failed-precondition",
      "Quantidade de tokens insuficiente."
    );
  }

  // Calcular valor da venda
  const priceCents = startup.currentTokenPriceCents;
  const totalCents = quantity * priceCents;

  // Creditar saldo
  await updateBalance(user.uid, totalCents);

  // Remover tokens (se zerar, remove investidor)
  await removeTokens(startupId, user.uid, quantity);

  // Salvar transação
  const transaction: TransactionDocument = {
    type: "sell",
    startupId,
    startupName: startup.name,
    quantity,
    priceCents,
    totalCents,
  };
  const transactionId = await saveTransaction(user.uid, transaction);

  return {
    data: {
      transactionId,
      startupId,
      quantity,
      totalCents,
    },
  };
});
