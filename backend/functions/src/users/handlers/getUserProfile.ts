/**
 * Handler: getUserProfile — retorna dados do perfil do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {getUserProfile as getProfile} from "../repositories/userRepository";

export const getUserProfile = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const profile = await getProfile(user.uid);

  return {
    data: {
      nomeCompleto: profile?.name ?? "",
      email: profile?.email ?? user.email ?? "",
      cpf: profile?.cpf ?? "",
      telefone: profile?.phone ?? "",
    },
  };
});
