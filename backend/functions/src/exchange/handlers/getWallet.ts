/**
 * Handler: getWallet — retorna dados da carteira do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando abre a tela de carteira.
 * Retorna: saldo, tokens que possui por startup, e totais.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {getBalance, getUserTokenPositions} from "../repositories/exchangeRepository";

export const getWallet = onCall(async (request) => {
  // 1. Verifica login
  const user = requireAuthenticatedUser(request);

  // 2. Busca saldo atual
  const balanceCents = await getBalance(user.uid);

  // 3. Busca tokens que o usuário possui em cada startup
  const positions = await getUserTokenPositions(user.uid);

  // 4. Retorna tudo pro Flutter
  return {
    data: {
      balanceCents,
      positions,
      totalStartups: positions.length,
      totalTokens: positions.reduce((sum, p) => sum + p.quantity, 0),
    },
  };
});
