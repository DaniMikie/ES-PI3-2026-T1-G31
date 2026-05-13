/**
 * Repository de Users — acesso ao Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {FieldValue} from "firebase-admin/firestore";
import {UserDocument} from "../types";
import {db} from "../../startups/shared/firebase";

const usersCollection = db.collection("users");

export async function createUserProfile(
  uid: string,
  data: UserDocument
): Promise<void> {
  await usersCollection.doc(uid).set({
    ...data,
    createdAt: FieldValue.serverTimestamp(),
  });
}

export async function getUserProfile(
  uid: string
): Promise<UserDocument | undefined> {
  const snapshot = await usersCollection.doc(uid).get();
  if (!snapshot.exists) {
    return undefined;
  }
  return snapshot.data() as UserDocument;
}
