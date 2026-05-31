/**
 * Handler: getStartupTokenHistory — historico de preco de uma startup
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Busca todas as transacoes de uma startup (de qualquer usuario),
 * agrupa por periodo e calcula preco medio. Adiciona o preco atual
 * (currentTokenPriceCents) como ultimo ponto pra consistencia com o valor exibido.
 * Usado pra grafico de valorizacao na tela da startup.
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {db} from "../../startups/shared/firebase";

export const getStartupTokenHistory = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const startupId = normalizeString(request.data?.startupId);
  if (!startupId) throw new HttpsError("invalid-argument", "Informe startupId.");

  const period = request.data?.period as string ?? "mes";

  let daysBack: number;
  let groupBy: string;

  switch (period) {
    case "dia": daysBack = 1; groupBy = "hora"; break;
    case "semana": daysBack = 7; groupBy = "dia"; break;
    case "mes": daysBack = 30; groupBy = "dia"; break;
    case "6meses": daysBack = 180; groupBy = "semana"; break;
    case "ytd": daysBack = 365; groupBy = "mes"; break;
    default: daysBack = 30; groupBy = "dia";
  }

  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysBack);

  // Busca transacoes de TODOS os usuarios nessa startup
  const snapshot = await db
    .collectionGroup("transactions")
    .where("startupId", "==", startupId)
    .where("createdAt", ">=", startDate)
    .orderBy("createdAt", "asc")
    .get();

  if (snapshot.empty) {
    return {data: {points: [], variation: 0, period}};
  }

  // Agrupa transações por intervalo de tempo e calcula preço médio ponderado
  // totalCents = soma de (preço × quantidade) | totalQty = soma das quantidades
  // Preço médio = totalCents / totalQty
  const groups: Map<string, {totalCents: number; totalQty: number}> = new Map();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const priceCents = data.priceCents as number ?? 0;
    const qty = data.quantity as number ?? 0;
    if (data.type === "credit" || priceCents <= 0 || qty <= 0) continue;

    const createdAt = data.createdAt?.toDate?.() ?? new Date();
    const localDate = new Date(createdAt.getTime() - 3 * 60 * 60 * 1000);
    let label: string;

    if (groupBy === "hora") {
      label = `${String(localDate.getHours()).padStart(2, "0")}:00`;
    } else if (groupBy === "dia") {
      label = `${String(localDate.getDate()).padStart(2, "0")}/${String(localDate.getMonth() + 1).padStart(2, "0")}`;
    } else if (groupBy === "semana") {
      const weekNum = Math.ceil(localDate.getDate() / 7);
      label = `S${weekNum}/${localDate.getMonth() + 1}`;
    } else {
      const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
      label = months[localDate.getMonth()];
    }

    const existing = groups.get(label) ?? {totalCents: 0, totalQty: 0};
    existing.totalCents += priceCents * qty;
    existing.totalQty += qty;
    groups.set(label, existing);
  }

  const points: Array<{label: string; value: number}> = [];
  for (const [label, data] of groups.entries()) {
    const avgPrice = data.totalQty > 0 ? Math.round(data.totalCents / data.totalQty) : 0;
    points.push({label, value: avgPrice});
  }

  // Se só tem 1 ponto, duplica pra o gráfico conseguir renderizar (precisa de >= 2)
  if (points.length === 1) {
    const single = points[0];
    points.unshift({label: "início", value: single.value});
  }

  // Adiciona preço atual real como último ponto
  // Garante que o gráfico termine no valor consistente com "Por token" exibido na tela
  const startupDoc = await db.collection("startups").doc(startupId).get();
  const currentPrice = startupDoc.data()?.currentTokenPriceCents as number ?? 0;
  if (currentPrice > 0) {
    points.push({label: "atual", value: currentPrice});
  }

  // Variação % entre primeiro e último ponto do período
  // Indica se o token valorizou (+) ou desvalorizou (-) no período selecionado
  let variation = 0;
  if (points.length >= 2) {
    const first = points[0].value;
    const last = points[points.length - 1].value;
    if (first > 0) {
      variation = Math.round(((last - first) / first) * 10000) / 100;
    }
  }

  return {data: {points, variation, period}};
});
