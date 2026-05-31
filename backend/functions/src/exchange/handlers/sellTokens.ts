/**
 * Handler: sellTokens — venda simulada de tokens
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o investidor quer vender tokens.
 * Fluxo: valida tokens suficientes → credita saldo → remove tokens → salva transação.
 * Se vender todos os tokens, o usuário deixa de ser investidor.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {
  getTokenPosition,
  updateBalance,
  removeTokens,
  saveTransaction,
  recalculateTokenPrice,
} from "../repositories/exchangeRepository";
import {TransactionDocument} from "../types";

export const sellTokens = onCall(async (request) => {
  // 1. Verifica login
  const user = requireAuthenticatedUser(request);

  // 2. Pega dados do Flutter: qual startup e quantos tokens vender
  const startupId = normalizeString(request.data?.startupId);
  const quantity = request.data?.quantity;

  // 3. Valida os dados recebidos
  if (!startupId) {
    throw new HttpsError("invalid-argument", "Informe o startupId.");
  }
  if (typeof quantity !== "number" || quantity <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Informe uma quantidade valida maior que zero."
    );
  }

  // 4. Verifica se a startup existe
  const startup = await getStartupById(startupId);
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  // 5. Verifica se o usuário tem tokens suficientes pra vender
  const position = await getTokenPosition(startupId, user.uid);
  if (!position || position.quantity < quantity) {
    throw new HttpsError(
      "failed-precondition",
      "Quantidade de tokens insuficiente."
    );
  }

  // 6. Calcula o valor da venda (quantidade × preço atual)
  const priceCents = startup.currentTokenPriceCents;
  const totalCents = quantity * priceCents;

  // 7. Credita o valor no saldo do usuário
  await updateBalance(user.uid, totalCents);

  // 8. Remove tokens (se zerar, remove status de investidor)
  await removeTokens(startupId, user.uid, quantity);

  // 9. Salva a transação no histórico
  const transaction: TransactionDocument = {
    type: "sell",
    startupId,
    startupName: startup.name,
    quantity,
    priceCents,
    totalCents,
  };
  const transactionId = await saveTransaction(user.uid, transaction);

  // 10. Recalcula o preço do token (não bloqueia a resposta se falhar)
  try {
    await recalculateTokenPrice(startupId);
  } catch (e) {
    logger.error("Erro ao recalcular preco:", e);
  }

  // 11. Retorna resultado pro Flutter
  return {
    data: {
      transactionId,
      startupId,
      quantity,
      totalCents,
    },
  };
});
