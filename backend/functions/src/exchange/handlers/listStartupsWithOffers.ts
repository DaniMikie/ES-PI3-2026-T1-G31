/**
 * Handler: listStartupsWithOffers — retorna IDs de startups com ofertas ativas
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Retorna lista de startupIds que possuem pelo menos uma oferta ativa
 * de outro usuário (exclui ofertas do próprio usuário logado).
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const listStartupsWithOffers = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const snapshot = await db.collection("offers")
    .where("status", "==", "active")
    .get();

  const startupIds = new Set<string>();
  for (const doc of snapshot.docs) {
    if (doc.data().sellerUid !== user.uid) {
      startupIds.add(doc.data().startupId);
    }
  }

  return {
    data: {
      startupIds: Array.from(startupIds),
    },
  };
});
