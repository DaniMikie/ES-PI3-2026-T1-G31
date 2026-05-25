/**
 * Handler: getStartupUpdates — retorna atualizações e eventos de uma startup
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Retorna lista de atualizações/eventos publicados pela startup.
 * Ordenados do mais recente pro mais antigo.
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {db} from "../shared/firebase";

export const getStartupUpdates = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const startupId = normalizeString(request.data?.startupId);
  if (!startupId) {
    throw new HttpsError("invalid-argument", "Informe startupId.");
  }

  const snapshot = await db
    .collection("startups")
    .doc(startupId)
    .collection("updates")
    .orderBy("createdAt", "desc")
    .limit(20)
    .get();

  const updates = snapshot.docs.map((doc) => ({
    id: doc.id,
    title: doc.get("title") ?? "",
    content: doc.get("content") ?? "",
    type: doc.get("type") ?? "update",
    createdAt: doc.get("createdAt")?.toDate?.()?.toISOString?.() ?? null,
  }));

  return {
    data: {
      updates,
      count: updates.length,
    },
  };
});
