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

  const filteredDocs = snapshot.docs
    .filter((doc) => doc.data().sellerUid !== user.uid);

  // Busca nomes dos vendedores
  const sellerUids = [...new Set(filteredDocs.map((doc) => doc.data().sellerUid as string))];
  const sellerNames: Record<string, string> = {};
  for (const uid of sellerUids) {
    const userDoc = await db.collection("users").doc(uid).get();
    sellerNames[uid] = userDoc.data()?.name ?? userDoc.data()?.email ?? "Vendedor";
  }

  const offers = filteredDocs.map((doc) => ({
    id: doc.id,
    startupId: doc.data().startupId,
    startupName: doc.data().startupName,
    quantity: doc.data().quantity,
    priceCents: doc.data().priceCents,
    sellerEmail: doc.data().sellerEmail,
    sellerName: sellerNames[doc.data().sellerUid] ?? "Vendedor",
    createdAt: doc.data().createdAt?.toDate?.()?.toISOString?.() ?? null,
  }));

  return {
    data: {
      offers,
      count: offers.length,
    },
  };
});
