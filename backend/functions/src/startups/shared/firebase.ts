/**
 * Inicialização do Firebase Admin — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Este arquivo inicializa o Firebase Admin SDK e exporta as instâncias
 * de Auth e Firestore que todos os outros arquivos usam.
 * É o ponto central de conexão com o Firebase.
 */

import {getAuth} from "firebase-admin/auth";
import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

// Só inicializa se ainda não foi inicializado (evita erro de duplicação)
if (getApps().length === 0) {
  initializeApp();
}

// Exporta instâncias pra uso em todo o projeto
export const auth = getAuth();   // Firebase Authentication
export const db = getFirestore(); // Firestore (banco de dados)
