/**
 * Handler: createOffer — cria oferta de venda no balcao
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Investidor anuncia tokens com preco que ele define.
 * Reserva os tokens (subtrai da posicao) ate alguem comprar ou ele cancelar.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {getTokenPosition, removeTokens} from "../repositories/exchangeRepository";
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

  // Verifica se tem tokens suficientes
  const position = await getTokenPosition(startupId, user.uid);
  if (!position || position.quantity < quantity) {
    throw new HttpsError("failed-precondition", "Tokens insuficientes para criar oferta.");
  }

  // Reserva tokens (remove da posicao)
  await removeTokens(startupId, user.uid, quantity);

  // Cria oferta
  const offerRef = await db.collection("offers").add({
    sellerUid: user.uid,
    sellerEmail: user.email ?? "",
    startupId,
    startupName: startup.name,
    quantity,
    priceCents,
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    data: {
      offerId: offerRef.id,
      startupId,
      quantity,
      priceCents,
    },
  };
});
