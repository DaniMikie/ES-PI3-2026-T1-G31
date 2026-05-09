/**
 * Handler: addCredits — adiciona saldo fictício na carteira do usuário
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import { onCall, HttpsError } from "firebase-functions/https";
import { requireAuthenticatedUser } from "../../startups/shared/auth";
import { updateBalance, getBalance } from "../repositories/exchangeRepository";

export const addCredits = onCall(async (request) => {
    const user = requireAuthenticatedUser(request);
    const amount = request.data?.amount;

    if(typeof amount !== "number" || amount <= 0){
        throw new HttpsError("invalid-argument", "Informe um valor valido maior que zero.");
    }

    await updateBalance(user.uid, amount);

    const newBalance = await getBalance(user.uid);

    return {
        data: {
            balanceeCents: newBalance,
        },
    };
});