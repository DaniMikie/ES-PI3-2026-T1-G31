/**
 * Tipos do módulo users — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Define a estrutura dos dados do usuário no Firestore.
 * Documento fica em: users/{uid}
 */

import {FieldValue, Timestamp} from "firebase-admin/firestore";

export type UserDocument = {
  name: string;              // Nome completo
  email: string;             // E-mail (mesmo do Firebase Auth)
  cpf: string;               // CPF do usuário
  phone: string;             // Telefone celular
  balanceCents?: number;     // Saldo da carteira em centavos
  mfaAtivo?: boolean;        // Preferência de autenticação multifator
  createdAt?: Timestamp | FieldValue;  // Data de criação do perfil
};
