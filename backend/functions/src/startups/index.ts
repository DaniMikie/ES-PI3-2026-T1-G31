/**
 * Exportações do módulo startups — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Cada export aqui registra uma Cloud Function no deploy.
 * O Flutter chama essas functions pelo nome.
 */

export {createStartupQuestion} from "./handlers/createStartupQuestion";
export {getStartupContent} from "./handlers/getStartupContent";
export {getStartupDetails} from "./handlers/getStartupDetails";
export {listStartups} from "./handlers/listStartups";
export {seedStartupCatalog} from "./handlers/seedStartupCatalog";