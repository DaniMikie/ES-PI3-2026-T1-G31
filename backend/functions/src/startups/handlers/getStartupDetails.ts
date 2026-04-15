/**
 * Handler: getStartupDetails — retorna detalhes completos de uma startup
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {
  getStartupById,
  listPublicQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";

export const getStartupDetails = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const startupId = normalizeString(request.data?.id);

  if (!startupId) {
    throw new HttpsError(
      "invalid-argument",
      "Informe o parametro id da startup."
    );
  }

  const startup = await getStartupById(startupId);
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  const isInvestor = await userIsInvestor(startupId, user.uid);
  const questions = await listPublicQuestions(startupId);

  return {
    data: {
      id: startupId,
      ...startup,
      createdAt: startup.createdAt?.toDate().toISOString() ?? null,
      updatedAt: startup.updatedAt?.toDate().toISOString() ?? null,
      publicQuestions: questions,
      access: {
        isInvestor,
        canTradeTokens: isInvestor,
        canSendPrivateQuestions: isInvestor,
      },
    },
  };
});
