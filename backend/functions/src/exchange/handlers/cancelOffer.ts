/**
 * Handler: cancelOffer — vendedor cancela oferta e recupera tokens
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {addTokens} from "../repositories/exchangeRepository";
import {db} from "../../startups/shared/firebase";

export const cancelOffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const offerId = normalizeString(request.data?.offerId);
  if (!offerId) throw new HttpsError("invalid-argument", "Informe offerId.");

  const offerRef = db.collection("offers").doc(offerId);
  const offerSnapshot = await offerRef.get();

  if (!offerSnapshot.exists) throw new HttpsError("not-found", "Oferta nao encontrada.");

  const offer = offerSnapshot.data()!;

  if (offer.sellerUid !== user.uid) throw new HttpsError("permission-denied", "Somente o vendedor pode cancelar.");
  if (offer.status !== "active") throw new HttpsError("failed-precondition", "Oferta nao pode ser cancelada.");

  // Devolve tokens pro vendedor
  await addTokens(offer.startupId, user.uid, offer.quantity, 0);

  // Marca como cancelada
  await offerRef.update({status: "cancelled"});

  return {
    data: {
      offerId,
      message: "Oferta cancelada. Tokens devolvidos.",
    },
  };
});
