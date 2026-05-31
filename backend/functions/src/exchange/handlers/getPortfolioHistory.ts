/**
 * Handler: getPortfolioHistory — histórico de variação do portfólio
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Retorna o histórico de preço de cada startup que o usuário investe,
 * calculando a variação % em relação ao preço médio de compra.
 * Inclui ponto base (0%) e ponto atual pra garantir visualização completa.
 * Retorna também quantity e currentPriceCents pra cálculo de lucro em R$.
 * Usado pra gráfico multi-linha na carteira.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {getUserTokenPositions} from "../repositories/exchangeRepository";
import {db} from "../../startups/shared/firebase";

export const getPortfolioHistory = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const period = request.data?.period as string ?? "mes";

  let daysBack: number;
  switch (period) {
    case "dia": daysBack = 1; break;
    case "semana": daysBack = 7; break;
    case "mes": daysBack = 30; break;
    case "6meses": daysBack = 180; break;
    case "ytd": daysBack = 365; break;
    default: daysBack = 30;
  }

  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysBack);

  // Busca posições do usuário (em quais startups investiu)
  const positions = await getUserTokenPositions(user.uid);

  if (positions.length === 0) {
    return {data: {lines: []}};
  }

  const colors = ["#2E7D32", "#1565C0", "#F57C00", "#7B1FA2", "#C62828"];
  const lines: Array<{
    startupId: string;
    startupName: string;
    color: string;
    avgBuyCents: number;
    quantity: number;
    currentPriceCents: number;
    points: Array<{timestamp: string; variation: number}>;
  }> = [];

  for (let i = 0; i < positions.length; i++) {
    const pos = positions[i];
    // Preço médio de compra = total investido / quantidade de tokens
    const avgBuyCents = pos.totalInvestedCents / pos.quantity;

    // Busca histórico de preço dessa startup (collection priceHistory)
    // Cada documento é um snapshot salvo quando o preço muda após uma transação
    const historySnapshot = await db
      .collection("startups")
      .doc(pos.startupId)
      .collection("priceHistory")
      .where("createdAt", ">=", startDate)
      .orderBy("createdAt", "asc")
      .limit(50)
      .get();

    // Busca nome da startup
    const startupDoc = await db.collection("startups").doc(pos.startupId).get();
    const startupName = startupDoc.data()?.name ?? pos.startupId;

    const points: Array<{timestamp: string; variation: number}> = [];

    // Ponto base (momento da compra = 0% variação) pra dar referência visual
    // Sem esse ponto, o gráfico começaria direto na primeira variação
    const baseLabel = daysBack <= 1 ? "00:00" : `${String(startDate.getDate()).padStart(2, "0")}/${String(startDate.getMonth() + 1).padStart(2, "0")}`;
    points.push({timestamp: baseLabel, variation: 0});

    for (const doc of historySnapshot.docs) {
      const price = doc.data().price as number ?? 0;
      const createdAt = doc.data().createdAt?.toDate?.() ?? new Date();
      const localDate = new Date(createdAt.getTime() - 3 * 60 * 60 * 1000);

      // Variação % = ((preço atual - preço médio de compra) / preço médio) × 100
      // Positivo = lucro, Negativo = prejuízo
      const variation = avgBuyCents > 0
        ? Math.round(((price - avgBuyCents) / avgBuyCents) * 10000) / 100
        : 0;

      const label = daysBack <= 1
        ? `${String(localDate.getHours()).padStart(2, "0")}:${String(localDate.getMinutes()).padStart(2, "0")}`
        : `${String(localDate.getDate()).padStart(2, "0")}/${String(localDate.getMonth() + 1).padStart(2, "0")}`;

      points.push({timestamp: label, variation});
    }

    // Adiciona ponto atual pra sempre ter o estado mais recente no gráfico
    // Usa o currentTokenPriceCents da startup (preço real atual)
    const currentPrice = pos.currentTokenPriceCents;
    const currentVariation = avgBuyCents > 0
      ? Math.round(((currentPrice - avgBuyCents) / avgBuyCents) * 10000) / 100
      : 0;
    const now = new Date(Date.now() - 3 * 60 * 60 * 1000);
    const nowLabel = daysBack <= 1
      ? `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`
      : "agora";
    points.push({timestamp: nowLabel, variation: currentVariation});

    lines.push({
      startupId: pos.startupId,
      startupName,
      color: colors[i % colors.length],
      avgBuyCents: Math.round(avgBuyCents),
      quantity: pos.quantity,
      currentPriceCents: pos.currentTokenPriceCents,
      points,
    });
  }

  return {data: {lines}};
});
