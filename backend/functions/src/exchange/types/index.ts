/**
 * Tipos do módulo exchange — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {FieldValue, Timestamp} from "firebase-admin/firestore";

/**
 * Posição de tokens do usuário em uma startup.
 * Fica em: startups/{startupId}/investors/{uid}
 */
export type TokenPosition = {
  quantity: number;
  totalInvestedCents: number;
  updatedAt?: Timestamp | FieldValue;
};

/**
 * Tipo de transação: compra ou venda.
 */
export type TransactionType = "buy" | "sell";

/**
 * Registro de uma transação (compra ou venda).
 * Fica em: users/{uid}/transactions/{transactionId}
 */
export type TransactionDocument = {
  type: TransactionType;
  startupId: string;
  startupName: string;
  quantity: number;
  priceCents: number;
  totalCents: number;
  createdAt?: Timestamp | FieldValue;
};
