/**
 * Handler: buyTokens — compra simulada de tokens
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {onCall, HttpsError} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {normalizeString} from "../../startups/shared/validation";
import {getStartupById} from "../../startups/repositories/startupRepository";
import {getBalance, updateBalance, addTokens, saveTransaction} from "../repositories/exchangeRepository";
import {TransactionDocument} from "../types";

export const buyTokens = onCall(async (request) => {
    const user = requireAuthenticatedUser(request);

    const startupId = normalizeString(request.data?.startupId);
    const quantity = request.data?.quantity;

    if(!startupId) {
        throw new HttpsError("invalid-argument", "Informe o startupId.");
    }
    if(typeof quantity !== "number" || quantity <= 0){
        throw new HttpsError("invalid-argument", "Informe uma quantidade maior que zero.");
    }

    const startup = await getStartupById(startupId);
    if(!startup){
        throw new HttpsError("not-found", "Startup não encontrada.");
    }

    const priceCents = startup.currentTokenPriceCents; //priceCents = preco de 1 token
    const totalCents = quantity * priceCents;

    const balance = await getBalance(user.uid);
    if (balance < totalCents) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
    }

    await updateBalance(user.uid, -totalCents);

    await addTokens(startupId, user.uid, quantity, totalCents);

    const transaction: TransactionDocument = {
        type: "buy",
        startupId,
        startupName: startup.name,
        quantity,
        priceCents,
        totalCents,
    };
    const transactionId = await saveTransaction(user.uid, transaction);

    return {
        data: {
            transactionId,
            startupId,
            quantity,
            totalCents,
            newBalance: balance - totalCents,
        },
    };
})