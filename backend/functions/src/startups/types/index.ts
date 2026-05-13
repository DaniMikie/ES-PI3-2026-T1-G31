/**
 * Tipos do módulo startups — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {FieldValue, Timestamp} from "firebase-admin/firestore";

export type StartupStage = "nova" | "em_operacao" | "em_expansao";

export type QuestionVisibility = "publica" | "privada";

export type AuthenticatedUser = {
  uid: string;
  email?: string;
};

export type Founder = {
  name: string;
  role: string;
  equityPercent: number;
  bio?: string;
};

export type ExternalMember = {
  name: string;
  role: string;
  organization?: string;
};

export type StartupDocument = {
  name: string;
  stage: StartupStage;
  shortDescription: string;
  description: string;
  executiveSummary: string;
  capitalRaisedCents: number;
  totalTokensIssued: number;
  currentTokenPriceCents: number;
  founders: Founder[];
  externalMembers: ExternalMember[];
  demoVideos: string[];
  pitchDeckUrl?: string;
  coverImageUrl?: string;
  tags: string[];
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
};

export type StartupListItem = {
  id: string;
  name: string;
  shortDescription: string;
  stage: StartupStage;
  capitalRaisedCents: number;
  totalTokensIssued: number;
  currentTokenPriceCents: number;
  coverImageUrl?: string;
  tags: string[];
};

export type StartupQuestionDocument = {
  authorUid: string;
  authorEmail?: string;
  text: string;
  visibility: QuestionVisibility;
  answer?: string;
  answeredAt?: Timestamp | FieldValue;
  createdAt?: Timestamp | FieldValue;
};
