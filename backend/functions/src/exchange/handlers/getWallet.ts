import { onCall } from "firebase-functions/https";
import { requireAuthenticatedUser } from "../../startups/shared/auth";
import { getBalance } from "../repositories/exchangeRepository";

export const getWallet = onCall(async (request) => {
    const user = requireAuthenticatedUser(request);

    const balanceCents = await getBalance(user.uid);

    return {
        data: {
            balanceCents,
        },
    };
});