/**
 * Handler: buyTokens — compra simulada de tokens
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o usuário confirma uma compra.
 * Fluxo: valida saldo → desconta → registra tokens → salva transação.
 * Ao comprar, o usuário automaticamente vira investidor daquela startup.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {getBalance, updateBalance, addTokens, saveTransaction, recalculateTokenPrice, getTotalTokensSold, updateStartupCapital} from "../repositories/exchangeRepository";
import {TransactionDocument} from "../types";

export const buyTokens = onCall(async (request) => {
  // 1. Verifica login
  const user = requireAuthenticatedUser(request);

  // 2. Pega dados do Flutter: qual startup e quantos tokens
  const startupId = normalizeString(request.data?.startupId);
  const quantity = request.data?.quantity;

  // 3. Valida os dados recebidos
  if (!startupId) {
    throw new HttpsError("invalid-argument", "Informe o startupId.");
  }
  if (typeof quantity !== "number" || quantity <= 0) {
    throw new HttpsError("invalid-argument", "Informe uma quantidade maior que zero.");
  }

  // 4. Busca a startup no banco pra pegar o preço do token
  const startup = await getStartupById(startupId);
  if (!startup) {
    throw new HttpsError("not-found", "Startup não encontrada.");
  }

  // 5. Verifica se há tokens disponíveis (total emitido - já vendidos)
  const totalSold = await getTotalTokensSold(startupId);
  const available = startup.totalTokensIssued - totalSold;
  if (quantity > available) {
    throw new HttpsError(
      "failed-precondition",
      `Tokens insuficientes. Disponiveis: ${available}, solicitados: ${quantity}.`
    );
  }

  // 6. Calcula o custo total (quantidade × preço por token)
  const priceCents = startup.currentTokenPriceCents;
  const totalCents = quantity * priceCents;

  // 7. Verifica se o usuário tem saldo suficiente
  const balance = await getBalance(user.uid);
  if (balance < totalCents) {
    throw new HttpsError(
      "failed-precondition",
      `Saldo insuficiente. Necessario: R$${(totalCents / 100).toFixed(2)}, disponivel: R$${(balance / 100).toFixed(2)}.`
    );
  }

  // 8. Desconta o valor do saldo
  await updateBalance(user.uid, -totalCents);

  // 9. Registra os tokens comprados (e marca como investidor)
  await addTokens(startupId, user.uid, quantity, totalCents);

  // 10. Atualiza capital captado da startup
  await updateStartupCapital(startupId, totalCents);

  // 11. Salva a transação no histórico
  const transaction: TransactionDocument = {
    type: "buy",
    startupId,
    startupName: startup.name,
    quantity,
    priceCents,
    totalCents,
  };
  const transactionId = await saveTransaction(user.uid, transaction);

  // 12. Recalcula o preço do token (não bloqueia a resposta se falhar)
  try {
    await recalculateTokenPrice(startupId);
  } catch (e) {
    logger.error("Erro ao recalcular preco:", e);
  }

  // 13. Retorna resultado pro Flutter
  return {
    data: {
      transactionId,
      startupId,
      quantity,
      totalCents,
      newBalance: balance - totalCents,
    },
  };
});
