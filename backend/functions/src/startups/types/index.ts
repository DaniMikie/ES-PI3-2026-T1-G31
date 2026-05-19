/**
 * Tipos do módulo startups — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Define a estrutura de todos os dados relacionados a startups.
 * Esses tipos são usados no repository e nos handlers pra garantir
 * que os dados sempre têm a forma correta.
 */

import {FieldValue, Timestamp} from "firebase-admin/firestore";

// Estágios possíveis de uma startup
export type StartupStage = "nova" | "em_operacao" | "em_expansao";

// Visibilidade de uma pergunta
export type QuestionVisibility = "publica" | "privada";

// Dados do usuário logado (retornado pelo auth.ts)
export type AuthenticatedUser = {
  uid: string;
  email?: string;
};

// Sócio/fundador de uma startup
export type Founder = {
  name: string;           // Nome do sócio
  role: string;           // Cargo (CEO, CTO, etc)
  equityPercent: number;  // Percentual de participação
  bio?: string;           // Biografia (opcional)
};

// Membro externo (mentor, conselheiro)
export type ExternalMember = {
  name: string;
  role: string;
  organization?: string;  // Organização (ex: "Mescla")
};

// Documento COMPLETO de uma startup no Firestore (todos os campos)
// Fica em: startups/{startupId}
export type StartupDocument = {
  name: string;
  stage: StartupStage;
  shortDescription: string;
  description: string;
  executiveSummary: string;
  capitalRaisedCents: number;       // Capital levantado em centavos
  totalTokensIssued: number;        // Total de tokens emitidos
  currentTokenPriceCents: number;   // Preço atual por token em centavos
  founders: Founder[];
  externalMembers: ExternalMember[];
  demoVideos: string[];             // URLs de vídeos demonstrativos
  pitchDeckUrl?: string;
  coverImageUrl?: string;
  tags: string[];
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
};

// Versão RESUMIDA da startup (usada na listagem do catálogo)
// Evita mandar dados desnecessários pro Flutter quando só precisa da lista
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

// Documento de uma pergunta feita pra uma startup
// Fica em: startups/{startupId}/questions/{questionId}
export type StartupQuestionDocument = {
  authorUid: string;                    // UID de quem perguntou
  authorEmail?: string;                 // Email de quem perguntou
  text: string;                         // Texto da pergunta
  visibility: QuestionVisibility;       // Pública ou privada
  answer?: string;                      // Resposta do empreendedor (se tiver)
  answeredAt?: Timestamp | FieldValue;  // Data da resposta
  createdAt?: Timestamp | FieldValue;   // Data da pergunta
};
