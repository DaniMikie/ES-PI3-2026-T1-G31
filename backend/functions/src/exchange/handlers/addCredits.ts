/**
 * Handler: addCredits — adiciona saldo fictício na carteira do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o usuário clica em "Depositar".
 * Recebe o valor em centavos, valida, e soma no saldo.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {updateBalance, getBalance} from "../repositories/exchangeRepository";

export const addCredits = onCall(async (request) => {
  // 1. Verifica se o usuário está logado
  const user = requireAuthenticatedUser(request);

  // 2. Pega o valor que o Flutter mandou (em centavos)
  const amount = request.data?.amount;

  // 3. Valida: precisa ser número e maior que zero
  if (typeof amount !== "number" || amount <= 0) {
    throw new HttpsError("invalid-argument", "Informe um valor valido maior que zero.");
  }

  // 4. Soma o valor no saldo do usuário
  await updateBalance(user.uid, amount);

  // 5. Busca o saldo atualizado pra retornar pro Flutter
  const newBalance = await getBalance(user.uid);

  // 6. Retorna o novo saldo
  return {
    data: {
      balanceCents: newBalance,
    },
  };
});
