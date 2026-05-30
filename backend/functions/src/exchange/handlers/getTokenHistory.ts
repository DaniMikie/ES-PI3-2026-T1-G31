/**
 * Handler: getTokenHistory — retorna historico de patrimonio pra grafico
 * Autor: Daniela Mikie Kikuchi Goncalves | RA: 25003068
 *
 * Calcula o patrimonio acumulado do usuario (valor total dos tokens que possui)
 * a cada transacao. Compras aumentam o patrimonio, vendas diminuem.
 * Cada ponto inclui o tipo (buy/sell) pra diferenciar visualmente no grafico.
 * Usado pra alimentar o grafico de patrimonio na carteira.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {db} from "../../startups/shared/firebase";

export const getTokenHistory = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const period = request.data?.period as string ?? "mes";

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
    return {
      data: {
        points: [],
        variation: 0,
        period,
      },
    };
  }

  // Calcula patrimônio acumulado (valor total dos tokens que o usuário possui)
  // A cada transação, atualiza a posição e calcula o valor total.
  // positions: mapa de startupId → {quantidade de tokens, último preço negociado}
  const positions: Map<string, {qty: number; lastPrice: number}> = new Map();
  const points: Array<{label: string; value: number; type: string}> = [];

  for (const doc of transactionsSnapshot.docs) {
    const data = doc.data();
    const createdAt = data.createdAt?.toDate?.() ?? new Date();
    // Ajusta pra horário de Brasília (UTC-3)
    const localDate = new Date(createdAt.getTime() - 3 * 60 * 60 * 1000);
    const priceCents = data.priceCents as number ?? 0;
    const qty = data.quantity as number ?? 0;
    const type = data.type as string ?? "buy";
    const startupId = data.startupId as string ?? "";

    // Ignora créditos (adição de saldo) — não envolvem tokens
    if (type === "credit" || priceCents <= 0 || qty <= 0) continue;

    // Atualiza posição do usuário nessa startup
    // Compra: soma tokens | Venda: subtrai tokens
    const pos = positions.get(startupId) ?? {qty: 0, lastPrice: 0};
    if (type === "buy") {
      pos.qty += qty;
    } else if (type === "sell") {
      pos.qty = Math.max(0, pos.qty - qty);
    }
    pos.lastPrice = priceCents;
    positions.set(startupId, pos);

    // Patrimônio = soma de (quantidade × preço) de cada startup
    // Isso faz o gráfico subir em compras e descer em vendas
    let totalPatrimony = 0;
    for (const [, p] of positions.entries()) {
      totalPatrimony += p.qty * p.lastPrice;
    }

    // Gera label do eixo X conforme agrupamento (hora, dia, semana, mês)
    let label: string;
    if (groupBy === "hora") {
      label = `${String(localDate.getHours()).padStart(2, "0")}:${String(localDate.getMinutes()).padStart(2, "0")}`;
    } else if (groupBy === "dia") {
      label = `${String(localDate.getDate()).padStart(2, "0")}/${String(localDate.getMonth() + 1).padStart(2, "0")}`;
    } else if (groupBy === "semana") {
      const weekNum = Math.ceil(localDate.getDate() / 7);
      label = `S${weekNum}/${localDate.getMonth() + 1}`;
    } else {
      const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
      label = months[localDate.getMonth()];
    }

    points.push({label, value: totalPatrimony, type});
  }

  // Se só tem 1 ponto, adiciona ponto inicial zerado pra o gráfico renderizar
  // (o CustomPaint precisa de pelo menos 2 pontos pra desenhar uma linha)
  if (points.length === 1) {
    points.unshift({label: "início", value: 0, type: "buy"});
  }

  // Calcula variação percentual entre primeiro e último ponto
  // Fórmula: ((último - primeiro) / primeiro) × 100
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
