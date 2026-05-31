/**
 * Handler: getUserProfile — retorna dados do perfil do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * O Flutter chama essa function quando abre a tela de perfil.
 * Busca os dados salvos no Firestore e retorna pro app.
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {getUserProfile as getProfile} from "../repositories/userRepository";

export const getUserProfile = onCall(async (request) => {
  // 1. Verifica login
  const user = requireAuthenticatedUser(request);

  // 2. Busca o perfil no Firestore
  const profile = await getProfile(user.uid);

  // 3. Retorna os dados (usa valores do Auth como fallback se não tiver no Firestore)
  return {
    data: {
      nomeCompleto: profile?.name ?? "",
      email: profile?.email ?? user.email ?? "",
      cpf: profile?.cpf ?? "",
      telefone: profile?.phone ?? "",
      mfaAtivo: profile?.mfaAtivo ?? false,
    },
  };
});
