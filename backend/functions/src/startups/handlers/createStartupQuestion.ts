/**
 * Handler: createStartupQuestion — cria pergunta para uma startup
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Permite usuários enviarem perguntas para startups.
 * Perguntas públicas: qualquer usuário logado pode enviar.
 * Perguntas privadas: apenas investidores daquela startup podem enviar.
 */

import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import {allowedVisibilities} from "../shared/constants";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {
  createQuestion,
  getStartupById,
  userIsInvestor,
} from "../repositories/startupRepository";
import {QuestionVisibility, StartupQuestionDocument} from "../types";

export const createStartupQuestion = onCall(async (request) => {
  // Verifica login
  const user = requireAuthenticatedUser(request);

  // Pega dados do Flutter
  const startupId = normalizeString(request.data?.startupId);
  const text = normalizeString(request.data?.text);
  const visibility = normalizeString(request.data?.visibility) ?? "publica";

  // Valida campos obrigatórios
  if (!startupId || !text) {
    throw new HttpsError("invalid-argument", "Informe startupId e text.");
  }

  // Valida se a visibilidade é um valor aceito
  if (!allowedVisibilities.includes(visibility as QuestionVisibility)) {
    throw new HttpsError(
      "invalid-argument",
      "Visibility invalida. Use publica ou privada."
    );
  }

  // Verifica se a startup existe
  const startup = await getStartupById(startupId);
  if (!startup) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  // Se for pergunta privada, só investidor pode enviar
  if (visibility === "privada") {
    const isInvestor = await userIsInvestor(startupId, user.uid);
    if (!isInvestor) {
      throw new HttpsError(
        "permission-denied",
        "Somente investidores desta startup podem enviar perguntas privadas."
      );
    }
  }

  // Monta o documento da pergunta
  const question: StartupQuestionDocument = {
    authorUid: user.uid,
    authorEmail: user.email,
    text,
    visibility: visibility as QuestionVisibility,
    createdAt: FieldValue.serverTimestamp(),
  };

  // Salva na subcoleção startups/{startupId}/questions
  const questionId = await createQuestion(startupId, question);

  // Loga a ação pra monitoramento
  logger.info("Pergunta criada para startup.", {
    startupId,
    questionId,
    visibility,
  });

  return {
    data: {
      id: questionId,
      startupId,
      visibility,
    },
  };
});
