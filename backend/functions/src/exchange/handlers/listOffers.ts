/**
 * Handler: listOffers — lista ofertas ativas de uma startup
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {db} from "../../startups/shared/firebase";

export const listOffers = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const startupId = normalizeString(request.data?.startupId);

  let query = db.collection("offers")
    .where("status", "==", "active");

  if (startupId) {
    query = query.where("startupId", "==", startupId);
  }

  const snapshot = await query.limit(50).get();

  const offers = snapshot.docs
    .filter((doc) => doc.data().sellerUid !== user.uid) // nao mostra ofertas proprias
    .map((doc) => ({
      id: doc.id,
      startupId: doc.data().startupId,
      startupName: doc.data().startupName,
      quantity: doc.data().quantity,
      priceCents: doc.data().priceCents,
      sellerEmail: doc.data().sellerEmail,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString?.() ?? null,
    }));

  return {
    data: {
      offers,
      count: offers.length,
    },
  };
});
