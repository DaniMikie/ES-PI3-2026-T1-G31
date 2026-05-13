/**
 * Handler: buyTokens — compra simulada de tokens
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o usuário confirma uma compra.
 * Fluxo: valida saldo → desconta → registra tokens → salva transação.
 * Ao comprar, o usuário automaticamente vira investidor daquela startup.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {getBalance, updateBalance, addTokens, saveTransaction} from "../repositories/exchangeRepository";
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

  // 5. Calcula o custo total (quantidade × preço por token)
  const priceCents = startup.currentTokenPriceCents;
  const totalCents = quantity * priceCents;

  // 6. Verifica se o usuário tem saldo suficiente
  const balance = await getBalance(user.uid);
  if (balance < totalCents) {
    throw new HttpsError("failed-precondition", "Saldo insuficiente.");
  }

  // 7. Desconta o valor do saldo
  await updateBalance(user.uid, -totalCents);

  // 8. Registra os tokens comprados (e marca como investidor)
  await addTokens(startupId, user.uid, quantity, totalCents);

  // 9. Salva a transação no histórico
  const transaction: TransactionDocument = {
    type: "buy",
    startupId,
    startupName: startup.name,
    quantity,
    priceCents,
    totalCents,
  };
  const transactionId = await saveTransaction(user.uid, transaction);

  // 10. Retorna resultado pro Flutter
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
