/**
 * Handler: listTransactions — retorna histórico de compras e vendas
 * Autor: KAUAN AURELIO LASMAR DIAS | RA: 25001590
 *
 * O Flutter chama essa function para exibir o extrato de operações.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {getTransactions} from "../repositories/exchangeRepository";

export const listTransactions = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const transactions = await getTransactions(user.uid);

  return {
    data: {
      transactions,
      totalTransactions: transactions.length,
    },
  };
});
