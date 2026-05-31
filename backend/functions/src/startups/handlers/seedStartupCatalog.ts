/**
 * Handler: seedStartupCatalog — popula o Firestore com startups de demo
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Cria as 5 startups de demonstração no banco.
 * No emulador: roda livre sem restrição.
 * Em produção: exige uma seedKey (variável de ambiente) pra evitar uso indevido.
 */

import {onCall} from "firebase-functions/https";
import {seedDemoStartups} from "../repositories/startupRepository";

export const seedStartupCatalog = onCall(async (request) => {
  // Cria as startups no Firestore
  const startupIds = await seedDemoStartups();

  return {
    data: {
      count: startupIds.length,
      ids: startupIds,
    },
  };
});
