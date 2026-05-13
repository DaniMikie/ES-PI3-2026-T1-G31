/**
 * Entry point das Firebase Functions — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import {setGlobalOptions} from "firebase-functions";

setGlobalOptions({maxInstances: 10});

export * from "./startups";
export * from "./exchange";
