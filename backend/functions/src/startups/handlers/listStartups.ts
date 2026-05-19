/**
 * Handler: listStartups — lista startups com filtros
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function pra exibir o catálogo de startups.
 * Suporta filtro por estágio (nova, em_operacao, em_expansao) e busca por texto.
 * Retorna versão resumida das startups (StartupListItem), ordenada por nome.
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {allowedStages} from "../shared/constants";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {listStartupItems} from "../repositories/startupRepository";
import {StartupStage} from "../types";

export const listStartups = onCall(async (request) => {
  // Exige login
  requireAuthenticatedUser(request);

  // Pega filtros do Flutter (opcionais)
  const stage = normalizeString(request.data?.stage);
  const search = normalizeString(request.data?.search)
    ?.toLocaleLowerCase("pt-BR");

  // Valida se o estágio é um valor permitido
  if (stage && !allowedStages.includes(stage as StartupStage)) {
    throw new HttpsError(
      "invalid-argument",
      "Filtro stage invalido. Use nova, em_operacao ou em_expansao."
    );
  }

  // Busca todas as startups e aplica filtros em memória
  const startups = (await listStartupItems())
    // Filtra por estágio (se mandou)
    .filter((startup) => !stage || startup.stage === stage)
    // Filtra por texto de busca (nome, descrição, tags)
    .filter((startup) => {
      if (!search) return true;

      const searchable = [
        startup.name,
        startup.shortDescription,
        startup.stage,
        ...startup.tags,
      ].join(" ").toLocaleLowerCase("pt-BR");

      return searchable.includes(search);
    })
    // Ordena por nome em português
    .sort((left, right) => left.name.localeCompare(right.name, "pt-BR"));

  return {
    count: startups.length,
    filters: {
      availableStages: allowedStages,
      stage: stage ?? null,
      search: search ?? null,
    },
    data: startups,
  };
});
