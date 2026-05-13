/**
 * Handler: seedStartupCatalog — popula o Firestore com startups de demo
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Cria as 5 startups de demonstração no banco.
 * No emulador: roda livre sem restrição.
 * Em produção: exige uma seedKey (variável de ambiente) pra evitar uso indevido.
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {seedDemoStartups} from "../repositories/startupRepository";
import {normalizeString} from "../shared/validation";

export const seedStartupCatalog = onCall(async (request) => {
  // Em produção, exige chave de segurança
  if (!process.env.FUNCTIONS_EMULATOR) {
    const seedKey = normalizeString(request.data?.seedKey);

    if (
      !process.env.SEED_STARTUP_CATALOG_KEY ||
      seedKey !== process.env.SEED_STARTUP_CATALOG_KEY
    ) {
      throw new HttpsError(
        "permission-denied",
        "Seed bloqueado fora do emulator sem seedKey valido."
      );
    }
  }

  // Cria as startups no Firestore
  const startupIds = await seedDemoStartups();

  return {
    data: {
      count: startupIds.length,
      ids: startupIds,
    },
  };
});
