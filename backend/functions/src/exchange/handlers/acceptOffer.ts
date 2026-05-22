/**
 * Handler: acceptOffer — comprador aceita oferta do balcao
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Transfere tokens do vendedor pro comprador e dinheiro do comprador pro vendedor.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getBalance, updateBalance, addTokens, saveTransaction} from "../repositories/exchangeRepository";
import {db} from "../../startups/shared/firebase";

export const acceptOffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const offerId = normalizeString(request.data?.offerId);
  if (!offerId) throw new HttpsError("invalid-argument", "Informe offerId.");

  // Busca oferta
  const offerRef = db.collection("offers").doc(offerId);
  const offerSnapshot = await offerRef.get();

  if (!offerSnapshot.exists) throw new HttpsError("not-found", "Oferta nao encontrada.");

  const offer = offerSnapshot.data()!;

  if (offer.status !== "active") throw new HttpsError("failed-precondition", "Oferta nao esta mais disponivel.");
  if (offer.sellerUid === user.uid) throw new HttpsError("invalid-argument", "Nao pode comprar sua propria oferta.");

  const totalCents = offer.quantity * offer.priceCents;

  // Verifica saldo do comprador
  const balance = await getBalance(user.uid);
  if (balance < totalCents) throw new HttpsError("failed-precondition", "Saldo insuficiente.");

  // Debita comprador
  await updateBalance(user.uid, -totalCents);

  // Credita vendedor
  await updateBalance(offer.sellerUid, totalCents);

  // Transfere tokens pro comprador
  await addTokens(offer.startupId, user.uid, offer.quantity, totalCents);

  // Marca oferta como vendida
  await offerRef.update({
    status: "sold",
    buyerUid: user.uid,
    soldAt: FieldValue.serverTimestamp(),
  });

  // Salva transacao pra comprador
  await saveTransaction(user.uid, {
    type: "buy",
    startupId: offer.startupId,
    startupName: offer.startupName,
    quantity: offer.quantity,
    priceCents: offer.priceCents,
    totalCents,
  });

  // Salva transacao pra vendedor
  await saveTransaction(offer.sellerUid, {
    type: "sell",
    startupId: offer.startupId,
    startupName: offer.startupName,
    quantity: offer.quantity,
    priceCents: offer.priceCents,
    totalCents,
  });

  return {
    data: {
      offerId,
      startupId: offer.startupId,
      quantity: offer.quantity,
      totalCents,
    },
  };
});
