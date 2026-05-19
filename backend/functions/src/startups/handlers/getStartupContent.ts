/**
 *  Handler: getStartupContent — retorna conteúdo de uma startup (detalhes + perguntas)
 *  Autor: Kauan Aurelio Lasmar Dias / RA: 25001590
<<<<<<< HEAD
 * 
=======

>>>>>>> develop
 */

import {HttpsError, onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";

import {
  getStartupById,
  listPublicQuestions,
} from "../repositories/startupRepository"; 

export const getStartupContent = onCall(async (request) => {

<<<<<<< HEAD
    const user = requireAuthenticatedUser(request);
=======
    requireAuthenticatedUser(request);
>>>>>>> develop

    const startupId = normalizeString(request.data?.id);

    if (!startupId) {
        throw new HttpsError(
            "invalid-argument",
            "Informe o parametro id da startup."
        );
    }

    const startup = await getStartupById(startupId);

    if (!startup) {
        throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    const publicQuestions = await listPublicQuestions(startupId);

    const response: any = {
        id: startupId,
        name: startup.name,
        stage: startup.stage,
    };

    if (startup.executiveSummary) {
        response.executiveSummary = startup.executiveSummary;
    }

    if (startup.demoVideos?.length) {
        response.demoVideos = startup.demoVideos;
    }

    if (startup.founders?.length) {
        response.founders = startup.founders;
    }

    if (publicQuestions?.length) {
        response.publicQuestions = publicQuestions;
    }

    return {
        data: response,
    };
});