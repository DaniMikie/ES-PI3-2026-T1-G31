/**
 * Constantes do módulo startups — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Arrays com valores permitidos, usados nos handlers pra validar
 * se o que o Flutter mandou é um valor aceito pelo sistema.
 */

import {QuestionVisibility, StartupStage} from "../types";

// Estágios válidos de uma startup (usados no filtro do catálogo)
export const allowedStages: StartupStage[] = [
  "nova",
  "em_operacao",
  "em_expansao",
];

// Visibilidades válidas de uma pergunta
export const allowedVisibilities: QuestionVisibility[] = [
  "publica",
  "privada",
];
