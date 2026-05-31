/**
 * Handler: acceptOffer — comprador aceita oferta do balcao
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Transfere tokens do vendedor pro comprador e dinheiro do comprador pro vendedor.
 * Usa transaction do Firestore pra garantir que dois compradores nao aceitem
 * a mesma oferta ao mesmo tempo (race condition).
 */

import {onCall, HttpsError} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import {FieldValue} from "firebase-admin/firestore";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {addTokens, saveTransaction, recalculateTokenPrice} from "../repositories/exchangeRepository";
import {db} from "../../startups/shared/firebase";

export const acceptOffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const offerId = normalizeString(request.data?.offerId);
  if (!offerId) throw new HttpsError("invalid-argument", "Informe offerId.");

  // Usa transaction pra garantir atomicidade:
  // - Lê a oferta e o saldo do comprador
  // - Verifica se a oferta ainda está ativa
  // - Debita comprador, credita vendedor, marca oferta como vendida
  // Se outro usuário tentar aceitar ao mesmo tempo, o Firestore rejeita
  const result = await db.runTransaction(async (transaction) => {
    const offerRef = db.collection("offers").doc(offerId);
    const offerSnapshot = await transaction.get(offerRef);

    if (!offerSnapshot.exists) throw new HttpsError("not-found", "Oferta nao encontrada.");

    const offer = offerSnapshot.data()!;

    if (offer.status !== "active") throw new HttpsError("failed-precondition", "Oferta nao esta mais disponivel.");
    if (offer.sellerUid === user.uid) throw new HttpsError("invalid-argument", "Nao pode comprar sua propria oferta.");

    const totalCents = offer.quantity * offer.priceCents;

    // Verifica saldo do comprador dentro da transaction
    const buyerRef = db.collection("users").doc(user.uid);
    const buyerSnapshot = await transaction.get(buyerRef);
    const balance = buyerSnapshot.data()?.balanceCents ?? 0;

    if (balance < totalCents) {
      throw new HttpsError(
        "failed-precondition",
        `Saldo insuficiente. Necessario: R${(totalCents / 100).toFixed(2)}, disponivel: R${(balance / 100).toFixed(2)}.`
      );
    }

    // Debita comprador
    transaction.update(buyerRef, {
      balanceCents: FieldValue.increment(-totalCents),
    });

    // Credita vendedor
    const sellerRef = db.collection("users").doc(offer.sellerUid);
    transaction.update(sellerRef, {
      balanceCents: FieldValue.increment(totalCents),
    });

    // Marca oferta como vendida
    transaction.update(offerRef, {
      status: "sold",
      buyerUid: user.uid,
      soldAt: FieldValue.serverTimestamp(),
    });

    return {offer, totalCents};
  });

  // Operações fora da transaction (não precisam ser atômicas)
  const {offer, totalCents} = result;

  // Transfere tokens pro comprador
  await addTokens(offer.startupId, user.uid, offer.quantity, totalCents);

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

  // Recalcula o preco do token (não bloqueia a resposta se falhar)
  try {
    await recalculateTokenPrice(offer.startupId);
  } catch (e) {
    logger.error("Erro ao recalcular preco:", e);
  }

  return {
    data: {
      offerId,
      startupId: offer.startupId,
      quantity: offer.quantity,
      totalCents,
    },
  };
});
