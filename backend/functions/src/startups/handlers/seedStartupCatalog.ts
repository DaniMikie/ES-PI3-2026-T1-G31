/**
 * Handler: seedStartupCatalog — popula o Firestore com startups de demo
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {seedDemoStartups} from "../repositories/startupRepository";
import {normalizeString} from "../shared/validation";

export const seedStartupCatalog = onCall(async (request) => {
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

  const startupIds = await seedDemoStartups();

  return {
    data: {
      count: startupIds.length,
      ids: startupIds,
    },
  };
});
