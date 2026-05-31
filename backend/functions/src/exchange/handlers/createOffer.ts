/**
 * Handler: createOffer — cria oferta de venda no balcao
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Investidor anuncia tokens com preco que ele define.
 * Reserva os tokens (subtrai da posicao) ate alguem comprar ou ele cancelar.
 * Usa transaction pra garantir que a reserva e a criação da oferta
 * aconteçam juntas — se uma falhar, nenhuma acontece.
 * NÃO registra como "sell" no histórico aqui — a venda só é registrada
 * quando alguém aceita a oferta (acceptOffer).
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {db} from "../../startups/shared/firebase";

export const createOffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const startupId = normalizeString(request.data?.startupId);
  const quantity = request.data?.quantity;
  const priceCents = request.data?.priceCents;

  if (!startupId) throw new HttpsError("invalid-argument", "Informe startupId.");
  if (typeof quantity !== "number" || quantity <= 0) throw new HttpsError("invalid-argument", "Quantidade invalida.");
  if (typeof priceCents !== "number" || priceCents <= 0) throw new HttpsError("invalid-argument", "Preco invalido.");

  const startup = await getStartupById(startupId);
  if (!startup) throw new HttpsError("not-found", "Startup nao encontrada.");

  // Transaction: verifica tokens, reserva e cria oferta atomicamente
  const offerId = await db.runTransaction(async (transaction) => {
    // Verifica se tem tokens suficientes
    const investorRef = db.collection("startups").doc(startupId).collection("investors").doc(user.uid);
    const investorSnapshot = await transaction.get(investorRef);

    if (!investorSnapshot.exists) {
      throw new HttpsError("failed-precondition", "Tokens insuficientes para criar oferta.");
    }

    const currentQuantity = investorSnapshot.data()?.quantity ?? 0;
    if (currentQuantity < quantity) {
      throw new HttpsError("failed-precondition", "Tokens insuficientes para criar oferta.");
    }

    // Reserva tokens (subtrai da posição)
    if (currentQuantity - quantity <= 0) {
      transaction.delete(investorRef);
    } else {
      transaction.update(investorRef, {
        quantity: FieldValue.increment(-quantity),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Cria oferta no mesmo transaction
    const offerRef = db.collection("offers").doc();
    transaction.set(offerRef, {
      sellerUid: user.uid,
      sellerEmail: user.email ?? "",
      startupId,
      startupName: startup.name,
      quantity,
      priceCents,
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
    });

    return offerRef.id;
  });

  return {
    data: {
      offerId,
      startupId,
      quantity,
      priceCents,
    },
  };
});
