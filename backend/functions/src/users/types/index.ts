/**
 * Tipos do módulo users — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {FieldValue, Timestamp} from "firebase-admin/firestore";

export type UserDocument = {
  name: string;
  email: string;
  cpf: string;
  phone: string;
  balanceCents?: number;
  mfaAtivo?: boolean;
  createdAt?: Timestamp | FieldValue;
};
