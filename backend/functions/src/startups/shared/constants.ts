/**
 * Constantes do módulo startups — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {QuestionVisibility, StartupStage} from "../types";

export const allowedStages: StartupStage[] = [
  "nova",
  "em_operacao",
  "em_expansao",
];

export const allowedVisibilities: QuestionVisibility[] = [
  "publica",
  "privada",
];
