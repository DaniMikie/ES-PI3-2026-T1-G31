/**
 * Handler: getStartupDetails — retorna detalhes completos de uma startup
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando o usuário clica numa startup no catálogo.
 * Retorna todos os dados: descrição, sócios, capital, tokens, perguntas públicas
 * e permissões do usuário (se é investidor, se pode negociar, etc).
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {
  getStartupById,
  listPublicQuestions,
  listPrivateQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";
import {getTokenPosition} from "../../exchange/repositories/exchangeRepository";

export const getStartupDetails = onCall(async (request) => {
  // Verifica login e pega dados do usuário
  const user = requireAuthenticatedUser(request);

  // Pega o ID da startup que o Flutter mandou
  const startupId = normalizeString(request.data?.id);

  if (!startupId) {
    throw new HttpsError(
      "invalid-argument",
      "Informe o parametro id da startup."
    );
  }

  // Busca a startup no Firestore
  const startup = await getStartupById(startupId);
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  // Verifica se o usuário é investidor dessa startup
  const isInvestor = await userIsInvestor(startupId, user.uid);
  const questions = await listPublicQuestions(startupId);
  const privateQuestions = isInvestor ? await listPrivateQuestions(startupId, user.uid) : [];
  const tokenPosition = await getTokenPosition(startupId, user.uid);

  return {
    data: {
      id: startupId,
      ...startup,
      createdAt: startup.createdAt?.toDate().toISOString() ?? null,
      updatedAt: startup.updatedAt?.toDate().toISOString() ?? null,
      publicQuestions: questions,
      privateQuestions: privateQuestions,
      access: {
        isInvestor,
        canTradeTokens: isInvestor,
        canSendPrivateQuestions: isInvestor,
        tokenQuantity: tokenPosition?.quantity ?? 0,
        totalInvestedCents: tokenPosition?.totalInvestedCents ?? 0,
      },
    },
  };
});
