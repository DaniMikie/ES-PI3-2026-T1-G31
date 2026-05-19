/**
 * Repository de Startups — acesso ao Firestore
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Este arquivo é o ÚNICO que acessa a coleção "startups" no Firestore.
 * Contém: dados demo, funções de leitura, escrita e seed.
 * Os handlers nunca acessam o banco direto — sempre passam por aqui.
 */

import {FieldValue} from "firebase-admin/firestore";
import {
  StartupDocument,
  StartupListItem,
  StartupQuestionDocument,
} from "../types";
import {db} from "../shared/firebase";

// Referência à coleção principal de startups no Firestore
const startupsCollection = db.collection("startups");

// ─── Dados de demonstração ───────────────────────────────────────────────────

const demoStartups: Array<{ id: string } & StartupDocument> = [
  {
    id: "greenpulse",
    name: "GreenPulse",
    stage: "em_operacao",
    shortDescription: "Plataforma de analise de consumo energetico com IA para empresas.",
    description:
      "A GreenPulse oferece uma plataforma inteligente de analise de consumo " +
      "energetico para empresas, utilizando IA para identificar oportunidades " +
      "de reducao de custos e emissoes.",
    executiveSummary:
      "Startup em operacao no setor cleantech, com foco em eficiencia " +
      "energetica empresarial por meio de inteligencia artificial.",
    capitalRaisedCents: 32000000,
    totalTokensIssued: 110000,
    currentTokenPriceCents: 291,
    founders: [
      {name: "Ana Souza", role: "CEO", equityPercent: 60},
      {name: "Carlos Lima", role: "CTO", equityPercent: 40},
    ],
    externalMembers: [
      {name: "Mariana Prado", role: "Mentora", organization: "Mescla"},
    ],
    demoVideos: ["https://exemplo.com/demo1"],
    tags: ["cleantech", "ia", "energia"],
  },
  {
    id: "medconnect",
    name: "MedConnect",
    stage: "em_expansao",
    shortDescription: "Aplicativo que conecta pacientes a medicos especialistas online.",
    description:
      "A MedConnect conecta pacientes a medicos especialistas por meio de " +
      "teleconsultas, facilitando o acesso a saude de qualidade de forma " +
      "rapida e acessivel.",
    executiveSummary:
      "Startup em crescimento no setor healthtech, com plataforma de " +
      "telemedicina voltada para conexao entre pacientes e especialistas.",
    capitalRaisedCents: 50000000,
    totalTokensIssued: 150000,
    currentTokenPriceCents: 333,
    founders: [
      {name: "Bruno Alves", role: "CEO", equityPercent: 50},
      {name: "Fernanda Rocha", role: "CTO", equityPercent: 50},
    ],
    externalMembers: [
      {name: "Dr. Ricardo Mendes", role: "Conselheiro", organization: "Mescla"},
    ],
    demoVideos: ["https://exemplo.com/demo2"],
    tags: ["healthtech", "telemedicina", "saude"],
  },
  {
    id: "agrosmart",
    name: "AgroSmart",
    stage: "nova",
    shortDescription: "Sistema inteligente de irrigacao com sensores IoT.",
    description:
      "A AgroSmart desenvolve sistemas de irrigacao inteligente baseados em " +
      "sensores IoT, otimizando o uso de agua e aumentando a produtividade " +
      "no campo.",
    executiveSummary:
      "Startup em validacao no setor agrotech, com solucao de irrigacao " +
      "inteligente via sensores IoT para pequenos e medios produtores rurais.",
    capitalRaisedCents: 20000000,
    totalTokensIssued: 80000,
    currentTokenPriceCents: 250,
    founders: [
      {name: "Lucas Martins", role: "CEO", equityPercent: 70},
      {name: "Paula Ribeiro", role: "CTO", equityPercent: 30},
    ],
    externalMembers: [
      {name: "Joao Batista", role: "Mentor", organization: "Mescla"},
    ],
    demoVideos: ["https://exemplo.com/demo3"],
    tags: ["agrotech", "iot", "sustentabilidade"],
  },
  {
    id: "eduflex",
    name: "EduFlex",
    stage: "em_operacao",
    shortDescription: "Plataforma de ensino adaptativo com IA personalizada.",
    description:
      "A EduFlex oferece uma plataforma de ensino adaptativo que utiliza " +
      "inteligencia artificial para personalizar o aprendizado de acordo com " +
      "o ritmo e perfil de cada estudante.",
    executiveSummary:
      "Startup em tracao no setor edtech, com plataforma de aprendizado " +
      "personalizado por IA voltada para estudantes do ensino basico e superior.",
    capitalRaisedCents: 40000000,
    totalTokensIssued: 120000,
    currentTokenPriceCents: 333,
    founders: [
      {name: "Juliana Costa", role: "CEO", equityPercent: 55},
      {name: "Rafael Dias", role: "CTO", equityPercent: 45},
    ],
    externalMembers: [
      {name: "Patricia Gomes", role: "Mentora", organization: "Mescla"},
    ],
    demoVideos: ["https://exemplo.com/demo4"],
    tags: ["edtech", "ia", "educacao"],
  },
  {
    id: "fintoken",
    name: "FinToken",
    stage: "nova",
    shortDescription: "Sistema de pagamentos digitais baseado em blockchain.",
    description:
      "A FinToken desenvolve um sistema de pagamentos digitais utilizando " +
      "tecnologia blockchain para garantir seguranca, transparencia e " +
      "rastreabilidade nas transacoes financeiras.",
    executiveSummary:
      "Startup em ideacao no setor fintech, com solucao de pagamentos " +
      "digitais baseada em blockchain para transacoes seguras e auditaveis.",
    capitalRaisedCents: 15000000,
    totalTokensIssued: 200000,
    currentTokenPriceCents: 75,
    founders: [
      {name: "Diego Fernandes", role: "CEO", equityPercent: 50},
      {name: "Camila Torres", role: "CTO", equityPercent: 50},
    ],
    externalMembers: [
      {name: "Andre Carvalho", role: "Conselheiro", organization: "Mescla"},
    ],
    demoVideos: ["https://exemplo.com/demo5"],
    tags: ["fintech", "blockchain", "pagamentos"],
  },
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

// Converte um StartupDocument completo em StartupListItem resumido (pra listagem)
function toListItem(id: string, startup: StartupDocument): StartupListItem {
  return {
    id,
    name: startup.name,
    stage: startup.stage,
    shortDescription: startup.shortDescription,
    capitalRaisedCents: startup.capitalRaisedCents,
    totalTokensIssued: startup.totalTokensIssued,
    currentTokenPriceCents: startup.currentTokenPriceCents,
    coverImageUrl: startup.coverImageUrl,
    tags: startup.tags,
  };
}

// ─── Funções exportadas ───────────────────────────────────────────────────────

// Busca até 100 startups e retorna versão resumida (pra catálogo)
export async function listStartupItems(): Promise<StartupListItem[]> {
  const snapshot = await startupsCollection.limit(100).get();
  return snapshot.docs.map((doc) =>
    toListItem(doc.id, doc.data() as StartupDocument)
  );
}

// Busca uma startup pelo ID. Retorna undefined se não existir.
export async function getStartupById(
  startupId: string
): Promise<StartupDocument | undefined> {
  const startupSnapshot = await startupsCollection.doc(startupId).get();
  if (!startupSnapshot.exists) {
    return undefined;
  }
  return startupSnapshot.data() as StartupDocument;
}

// Verifica se o usuário é investidor de uma startup (tem documento em investors)
export async function userIsInvestor(
  startupId: string,
  uid: string
): Promise<boolean> {
  const investorSnapshot = await startupsCollection
    .doc(startupId)
    .collection("investors")
    .doc(uid)
    .get();
  return investorSnapshot.exists;
}

// Busca perguntas públicas de uma startup, ordenadas da mais recente pra mais antiga
export async function listPublicQuestions(startupId: string) {
  const questionsSnapshot = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .where("visibility", "==", "publica")
    .limit(50)
    .get();

  return questionsSnapshot.docs
    .map((doc) => ({
      id: doc.id,
      text: doc.get("text"),
      answer: doc.get("answer") ?? null,
      answeredAt: doc.get("answeredAt")?.toDate?.()?.toISOString?.() ?? null,
      createdAt: doc.get("createdAt")?.toDate?.()?.toISOString?.() ?? null,
    }))
    .sort((left, right) =>
      String(right.createdAt ?? "").localeCompare(String(left.createdAt ?? ""))
    );
}

// Cria uma pergunta na subcoleção questions da startup. Retorna o ID gerado.
export async function createQuestion(
  startupId: string,
  question: StartupQuestionDocument
): Promise<string> {
  const questionRef = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .add(question);
  return questionRef.id;
}

// Cria as 5 startups demo no Firestore usando batch write (escrita em lote).
// merge: true = se já existir, atualiza em vez de sobrescrever.
export async function seedDemoStartups(): Promise<string[]> {
  const batch = db.batch();

  for (const startup of demoStartups) {
    const {id, ...data} = startup;
    const startupRef = startupsCollection.doc(id);
    batch.set(
      startupRef,
      {
        ...data,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  }

  await batch.commit();
  return demoStartups.map((startup) => startup.id);
}
