/**
 * Handler: listMyOffers — lista ofertas do proprio usuario
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Retorna todas as ofertas criadas pelo usuario (ativas, vendidas e canceladas).
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const listMyOffers = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const snapshot = await db.collection("offers")
    .where("sellerUid", "==", user.uid)
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();

  const offers = snapshot.docs.map((doc) => ({
    id: doc.id,
    startupId: doc.data().startupId,
    startupName: doc.data().startupName,
    quantity: doc.data().quantity,
    priceCents: doc.data().priceCents,
    status: doc.data().status,
    buyerUid: doc.data().buyerUid ?? null,
    createdAt: doc.data().createdAt?.toDate?.()?.toISOString?.() ?? null,
    soldAt: doc.data().soldAt?.toDate?.()?.toISOString?.() ?? null,
  }));

  return {
    data: {
      offers,
      count: offers.length,
    },
  };
});
