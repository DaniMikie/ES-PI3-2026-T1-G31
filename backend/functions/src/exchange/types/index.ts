/**
 * Tipos do módulo exchange — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Define a estrutura dos dados de tokens e transações.
 */

import {FieldValue, Timestamp} from "firebase-admin/firestore";

/**
 * Posição de tokens do usuário em uma startup.
 * Documento fica em: startups/{startupId}/investors/{uid}
 * Criado automaticamente na primeira compra.
 */
export type TokenPosition = {
  quantity: number;                    // Quantos tokens o usuário tem
  totalInvestedCents: number;          // Quanto gastou no total (em centavos)
  updatedAt?: Timestamp | FieldValue;  // Última atualização
};

/**
 * Tipo de transação: compra, venda ou crédito adicionado.
 */
export type TransactionType = "buy" | "sell" | "credit";

/**
 * Registro de uma transação (compra ou venda).
 * Documento fica em: users/{uid}/transactions/{transactionId}
 * Funciona como extrato bancário — cada operação gera um registro.
 */
export type TransactionDocument = {
  type: TransactionType;               // "buy" = compra, "sell" = venda
  startupId: string;                   // ID da startup envolvida
  startupName: string;                 // Nome da startup (pra exibir no histórico)
  quantity: number;                    // Quantos tokens foram comprados/vendidos
  priceCents: number;                  // Preço por token no momento da operação
  totalCents: number;                  // Valor total da operação (quantity × priceCents)
  createdAt?: Timestamp | FieldValue;  // Data/hora da transação
};

/**
 * Status de uma oferta no balcao.
 */
export type OfferStatus = "active" | "sold" | "cancelled";

/**
 * Oferta de venda de tokens no balcao.
 * Documento fica em: offers/{offerId}
 * Investidor define preco e quantidade. Outro usuario pode aceitar.
 */
export type OfferDocument = {
  sellerUid: string;
  sellerEmail?: string;
  startupId: string;
  startupName: string;
  quantity: number;
  priceCents: number;
  status: OfferStatus;
  buyerUid?: string;
  createdAt?: Timestamp | FieldValue;
  soldAt?: Timestamp | FieldValue;
};
