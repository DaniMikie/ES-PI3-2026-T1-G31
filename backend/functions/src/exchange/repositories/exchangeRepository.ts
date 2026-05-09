/**
 * Repository de exchange
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../startups/shared/firebase";

export async function getBalance(uid: string): Promise<number> {
    const exchangeSnapshot = await db.collection("users").doc(uid).get();
    const data = exchangeSnapshot.data();

    return data?.balanceCents ?? 0;
}

export async function updateBalance(uid: string, amountCents: number): Promise<void> {
    await db.collection("users").doc(uid).update({
        balanceCents: FieldValue.increment(amountCents),
    });
}