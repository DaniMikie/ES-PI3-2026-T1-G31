/**
 * Entry point das Firebase Functions — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Arquivo principal que o Firebase lê para registrar as Cloud Functions.
 * Exporta todos os módulos do projeto.
 */

import {setGlobalOptions} from "firebase-functions";

// Limita cada function a no máximo 10 instâncias simultâneas (controle de custo)
setGlobalOptions({maxInstances: 10});

// Exporta os 3 módulos — cada export registra as functions no deploy
export * from "./startups";  // catálogo, detalhes, perguntas, seed
export * from "./exchange";  // carteira, compra, venda de tokens
export * from "./users";     // cadastro, perfil, MFA
