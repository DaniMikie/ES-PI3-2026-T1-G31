/**
 * Handler: addCredits — adiciona saldo fictício na carteira do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o usuário clica em "Depositar".
 * Recebe o valor em centavos, valida, e soma no saldo.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {updateBalance, getBalance, saveTransaction} from "../repositories/exchangeRepository";

export const addCredits = onCall(async (request) => {
  // 1. Verifica se o usuário está logado
  const user = requireAuthenticatedUser(request);

  // 2. Pega o valor que o Flutter mandou (em centavos)
  const amount = request.data?.amount;

  // 3. Valida: precisa ser número inteiro e maior que zero
  if (typeof amount !== "number" || amount <= 0 || !Number.isFinite(amount)) {
    throw new HttpsError("invalid-argument", "Informe um valor valido maior que zero.");
  }

  // 4. Limite máximo: R$ 100.000.000.000.000,00 (100 trilhões em centavos)
  const MAX_AMOUNT = 10000000000000000;
  if (amount > MAX_AMOUNT) {
    throw new HttpsError("invalid-argument", "Valor excede o limite maximo permitido.");
  }

  // 4. Soma o valor no saldo do usuário
  await updateBalance(user.uid, amount);

  // 5. Registra a transação de crédito no histórico
  await saveTransaction(user.uid, {
    type: "credit",
    startupId: "",
    startupName: "",
    quantity: 0,
    priceCents: 0,
    totalCents: amount,
  });

  // 6. Busca o saldo atualizado pra retornar pro Flutter
  const newBalance = await getBalance(user.uid);

  // 7. Retorna o novo saldo
  return {
    data: {
      balanceCents: newBalance,
    },
  };
});
