/**
 * Handler: getTokenHistory — retorna historico de precos pra grafico
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Busca transacoes do usuario, agrupa por periodo e calcula preco medio.
 * Usado pra alimentar o grafico de valorizacao na carteira.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const getTokenHistory = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const period = request.data?.period as string ?? "mes";

  // Define quantos dias pra tras buscar e como agrupar
  let daysBack: number;
  let groupBy: string;

  switch (period) {
    case "dia":
      daysBack = 1;
      groupBy = "hora";
      break;
    case "semana":
      daysBack = 7;
      groupBy = "dia";
      break;
    case "mes":
      daysBack = 30;
      groupBy = "dia";
      break;
    case "6meses":
      daysBack = 180;
      groupBy = "semana";
      break;
    case "ytd":
      daysBack = 365;
      groupBy = "mes";
      break;
    default:
      daysBack = 30;
      groupBy = "dia";
  }

  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysBack);

  // Busca transacoes do usuario no periodo
  const transactionsSnapshot = await db
    .collection("users")
    .doc(user.uid)
    .collection("transactions")
    .where("createdAt", ">=", startDate)
    .orderBy("createdAt", "asc")
    .get();

  if (transactionsSnapshot.empty) {
    // Sem transacoes — retorna pontos vazios com preco base
    return {
      data: {
        points: [],
        variation: 0,
        period,
      },
    };
  }

  // Agrupa transacoes por intervalo
  const groups: Map<string, {totalCents: number; totalQty: number}> = new Map();

  for (const doc of transactionsSnapshot.docs) {
    const data = doc.data();
    const createdAt = data.createdAt?.toDate?.() ?? new Date();
    const priceCents = data.priceCents as number ?? 0;
    const qty = data.quantity as number ?? 0;

    let label: string;

    if (groupBy === "hora") {
      label = `${String(createdAt.getHours()).padStart(2, "0")}:00`;
    } else if (groupBy === "dia") {
      label = `${String(createdAt.getDate()).padStart(2, "0")}/${String(createdAt.getMonth() + 1).padStart(2, "0")}`;
    } else if (groupBy === "semana") {
      const weekNum = Math.ceil(createdAt.getDate() / 7);
      label = `S${weekNum}/${createdAt.getMonth() + 1}`;
    } else {
      const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
      label = months[createdAt.getMonth()];
    }

    const existing = groups.get(label) ?? {totalCents: 0, totalQty: 0};
    existing.totalCents += priceCents * qty;
    existing.totalQty += qty;
    groups.set(label, existing);
  }

  // Calcula preco medio por grupo
  const points: Array<{label: string; value: number}> = [];

  for (const [label, data] of groups.entries()) {
    const avgPrice = data.totalQty > 0 ? Math.round(data.totalCents / data.totalQty) : 0;
    points.push({label, value: avgPrice});
  }

  // Calcula variacao
  let variation = 0;
  if (points.length >= 2) {
    const first = points[0].value;
    const last = points[points.length - 1].value;
    if (first > 0) {
      variation = Math.round(((last - first) / first) * 10000) / 100;
    }
  }

  return {
    data: {
      points,
      variation,
      period,
    },
  };
});
