VISÃO GERAL DO QUE É ESSA AULA

Essa aula ensina como construir um backend organizado usando Firebase Functions + TDD (Test Driven Development)

Traduzindo:

Firebase Functions = backend (API)
TDD = você faz testes antes ou junto com o código
IDEIA PRINCIPAL DO PROFESSOR

Ele começa com um problema real:

“Muitos projetos começam bagunçados e depois viram um caos”

Problema comum:
MVP feito rápido
Sem organização
Quando cresce → impossível manter
Solução:
Já começar com estrutura organizada
Separar responsabilidades
Usar TDD
O QUE É TDD (SUPER IMPORTANTE)

TDD = Test Driven Development

Ideia:
Você escreve testes que validam o sistema antes ou junto com o código

Por que isso é bom?
Garante que tudo funciona
Permite várias pessoas trabalharem juntas
Evita bugs
PARTE 1 — TESTES (FLUTTER)

O PDF mostra um arquivo de teste (widget_test.dart).

O que esse teste faz?

Ele testa várias funções do backend:

1. Cria usuário de teste
_createAuthUserForTests()

Ele:

Cria usuário no Firebase Auth
Se já existir → faz login
2. Chama funções do backend
_callFunction("nomeDaFunction")

Isso simula o app chamando o backend

Testes que existem
Teste 1: seedStartupCatalog

Verifica se criou 3 startups:

biochip-campus
rota-verde
mentorai
Teste 2: listStartups

Testa:

filtro por estágio
busca por texto
Teste 3: getStartupDetails

Verifica:

detalhes completos da startup
acesso do usuário
Teste 4: createStartupQuestion

Verifica:

criação de pergunta
visibilidade (pública ou privada)
RESUMO DOS TESTES

O frontend (Flutter):

cria usuário
chama funções
valida resposta

Isso prova que o backend está funcionando

PARTE 2 — ESTRUTURA DO BACKEND

Essa parte é MUITO importante.

Estrutura:
functions/src/startups/
  handlers/
  repositories/
  shared/
  types/
Cada pasta tem uma função:
handlers

São as Firebase Functions

cada arquivo = uma função
repositories

Falam com o banco (Firestore)

Regra:

Function NÃO acessa banco direto

shared

Código reutilizável

auth
validação
config
types

Tipos (TypeScript)

estrutura dos dados
PARTE 3 — TYPES (MODELAGEM DOS DADOS)

Aqui ele define como os dados são organizados.

StartupStage
"nova" | "em_operacao" | "em_expansao"

estágio da startup

QuestionVisibility
"publica" | "privada"
AuthenticatedUser
{
  uid,
  email
}

usuário logado

Founder

sócio da startup

nome
cargo
% participação
📄 StartupDocument

estrutura COMPLETA da startup

Inclui:

nome
descrição
capital
sócios
vídeos
etc
StartupListItem

versão resumida (para lista)

IMPORTANTE:

evita mandar dados desnecessários
PARTE 4 — FUNCTIONS (HANDLERS)

Agora vem o coração do backend.

1. listStartups

Lista startups

Faz:
exige login
aplica filtro (stage)
aplica busca (search)
ordena
2. createStartupQuestion

Cria pergunta

Regras:
precisa estar logado
precisa enviar:
startupId
texto
REGRA IMPORTANTE:

Se for pergunta privada:
só investidor pode criar

3. getStartupDetails

Retorna detalhes completos

Inclui:

dados da startup
perguntas públicas
permissões do usuário
4. seedStartupCatalog

Cria startups fake (teste)

Segurança:
só funciona livre no emulador
em produção precisa de chave
PARTE 5 — REPOSITORY (BANCO)

Aqui acontece o acesso ao Firestore.

Funções principais:
listStartupItems()

pega startups do banco

getStartupById()

pega uma startup

userIsInvestor()

verifica se usuário é investidor

listPublicQuestions()

pega perguntas públicas

createQuestion()

salva pergunta

seedDemoStartups()

cria dados fake

OBSERVAÇÃO IMPORTANTE

Ele usa subcoleções

Exemplo:

startups/{startupId}/questions
PARTE 6 — SHARED
auth.ts

verifica login

Se não tiver:# Aula — Firebase Functions + TDD

## Visão Geral

Essa aula ensina como construir um backend organizado usando:

- Firebase Functions → backend (API)
- TDD (Test Driven Development) → desenvolvimento guiado por testes

---

## Ideia Principal do Professor

Ele começa com um problema real:

“Muitos projetos começam bagunçados e depois viram um caos”

### Problema comum
- MVP feito rápido  
- Sem organização  
- Quando cresce → impossível manter  

### Solução
- Começar organizado desde o início  
- Separar responsabilidades  
- Usar TDD  

---

## O que é TDD (SUPER IMPORTANTE)

TDD = Test Driven Development

Ideia:
Você escreve testes antes ou junto com o código

### Por que isso é bom?
- Garante que tudo funciona  
- Permite várias pessoas trabalharem juntas  
- Evita bugs  

---

# Parte 1 — Testes (Flutter)

Arquivo: widget_test.dart

### O que os testes fazem?

#### 1. Criar usuário de teste
_createAuthUserForTests()

- Cria usuário no Firebase Auth  
- Se já existir → faz login  

---

#### 2. Chamar funções do backend
_callFunction("nomeDaFunction")

Simula o app chamando o backend

---

### Testes existentes

#### Teste 1 — seedStartupCatalog
Verifica se criou 3 startups:
- biochip-campus  
- rota-verde  
- mentorai  

---

#### Teste 2 — listStartups
Testa:
- Filtro por estágio  
- Busca por texto  

---

#### Teste 3 — getStartupDetails
Verifica:
- Detalhes completos da startup  
- Acesso do usuário  

---

#### Teste 4 — createStartupQuestion
Verifica:
- Criação de pergunta  
- Visibilidade (pública ou privada)

---

### Resumo dos testes

O frontend (Flutter):

1. Cria usuário  
2. Chama funções  
3. Valida resposta  

Isso prova que o backend está funcionando

---

# Parte 2 — Estrutura do Backend

functions/src/startups/
  ├── handlers/
  ├── repositories/
  ├── shared/
  └── types/

### Função de cada pasta

#### handlers
- São as Firebase Functions  
- Cada arquivo = uma função  

---

#### repositories
- Falam com o banco (Firestore)

Regra importante:
Function NÃO acessa banco direto

---

#### shared
- Código reutilizável:
  - auth  
  - validação  
  - config  

---

#### types
- Tipos (TypeScript)  
- Define estrutura dos dados  

---

# Parte 3 — Types (Modelagem dos Dados)

### StartupStage
"nova" | "em_operacao" | "em_expansao"

---

### QuestionVisibility
"publica" | "privada"

---

### AuthenticatedUser
{
  uid,
  email
}

---

### Founder
- Nome  
- Cargo  
- % de participação  

---

### StartupDocument (COMPLETO)

Inclui:
- Nome  
- Descrição  
- Capital  
- Sócios  
- Vídeos  
- etc  

---

### StartupListItem (RESUMIDO)

Usado para listas

Importante:
Evita mandar dados desnecessários

---

# Parte 4 — Functions (Handlers)

## listStartups

Lista startups

Faz:
- Exige login  
- Aplica filtro (stage)  
- Aplica busca (search)  
- Ordena  

---

## createStartupQuestion

Cria pergunta

Regras:
- Precisa estar logado  
- Precisa enviar:
  - startupId  
  - texto  

Regra importante:
Se for pergunta privada → só investidor pode criar

---

## getStartupDetails

Retorna detalhes completos

Inclui:
- Dados da startup  
- Perguntas públicas  
- Permissões do usuário  

---

## seedStartupCatalog

Cria startups fake (para teste)

Segurança:
- Livre no emulador  
- Em produção → precisa de chave  

---

# Parte 5 — Repository (Banco)

Responsável pelo acesso ao Firestore

### Funções principais

- listStartupItems() → lista startups  
- getStartupById() → pega uma startup  
- userIsInvestor() → verifica investidor  
- listPublicQuestions() → perguntas públicas  
- createQuestion() → cria pergunta  
- seedDemoStartups() → dados fake  

---

### Estrutura no banco

startups/{startupId}/questions

Usa subcoleções

---

# Parte 6 — Shared

## auth.ts
- Verifica login  
- Se não tiver:
throw erro

---

## constants.ts
- Valores fixos:
  - estágios  
  - visibilidade  

---

## firebase.ts
- Inicializa Firebase  

---

## validation.ts
- Limpa strings:
  - Remove espaços  
  - Evita vazio  

---

# Parte 7 — Exportação

## startups/index.ts
- Exporta todas functions  

---

## index.ts (geral)
export * from "./startups";

Conecta tudo ao Firebase

---

# RESUMÃO FINAL (Essência da Aula)

## O que o professor quer que você aprenda:

1. Organização  
   - Separar responsabilidades  

2. Arquitetura limpa  
   - handler ≠ banco ≠ tipos  

3. Segurança  
   - Autenticação obrigatória  
   - Validação de dados  

4. Escalabilidade  
   - Crescer sem virar bagunça  

5. TDD  
   - Testar tudo  
   - Garantir funcionamento  

---

# Como pensar esse sistema

App (Flutter)
   ↓
Function (handler)
   ↓
Repository
   ↓
Firestore

Fluxo simples, limpo e escalável


throw erro
constants.ts

valores fixos

estágios
visibilidade
firebase.ts

inicializa Firebase

validation.ts

limpa strings

Ex:

remove espaço
evita vazio
PARTE 7 — EXPORTAÇÃO
startups/index.ts

exporta todas functions

index.ts (geral)

conecta tudo ao Firebase

export * from "./startups";
RESUMÃO FINAL (ESSÊNCIA DA AULA)
O que o professor quer que você aprenda:
1. Organização
separar responsabilidades
2. Arquitetura limpa
handler ≠ banco ≠ tipos
3. Segurança
autenticação obrigatória
validação de dados
4. Escalabilidade
projeto cresce sem virar bagunça
5. TDD
testar tudo
garantir funcionamento
COMO PENSAR ESSE SISTEMA (modo Dani hacker)

Imagina assim:

App (Flutter)
   ↓
Function (handler)
   ↓
Repository
   ↓
Firestore