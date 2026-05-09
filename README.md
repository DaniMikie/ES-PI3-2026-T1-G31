# MesclaInvest

## Sobre o Projeto

O **MesclaInvest** é um aplicativo mobile desenvolvido para a disciplina **Projeto Integrador 3** do curso de **Engenharia de Software da PUC-Campinas**.

A aplicação simula uma plataforma digital de investimento em **startups vinculadas ao Mescla**, permitindo que usuários acompanhem projetos, interajam com empreendedores e realizem **negociações simuladas de tokens**.

---

## Funcionalidades Implementadas

* **Autenticação de usuários** (cadastro, login, recuperação de senha)
* **Catálogo de startups** com filtros por estágio e busca por texto
* **Tela detalhada da startup** com sócios, capital, tokens, sumário executivo e perguntas públicas
* **Envio de perguntas** para empreendedores (públicas e privadas para investidores)
* **Perfil do usuário** com dados pessoais e preferência de MFA
* **Testes unitários** com Jest (TDD)

---

## Tecnologias Utilizadas

### Frontend (Mobile)
* **Flutter** / **Dart**

### Backend
* **Firebase Functions** (Node.js / TypeScript)

### Banco de Dados
* **Firebase Firestore**

### Autenticação
* **Firebase Authentication** (Email/Password)

### Ferramentas
* **Git** / **GitHub**
* **Visual Studio Code**
* **Android Studio**
* **Jest** (testes unitários)

---

## Estrutura do Projeto

```
PI3/
├── backend/                          # Firebase Functions (TypeScript)
│   ├── firebase.json                 # Configuração do projeto Firebase
│   ├── .firebaserc                   # ID do projeto (mescla-invest-5ee42)
│   ├── firestore.rules               # Regras de segurança do Firestore
│   ├── firestore.indexes.json        # Índices do Firestore
│   └── functions/
│       ├── package.json              # Dependências e scripts
│       ├── tsconfig.json             # Config TypeScript (VSCode)
│       ├── tsconfig.build.json       # Config TypeScript (build/deploy)
│       ├── jest.config.js            # Config dos testes
│       └── src/
│           ├── index.ts              # Entry point das functions
│           ├── startups/             # Módulo de startups
│           │   ├── index.ts          # Exportações do módulo
│           │   ├── handlers/         # Cloud Functions (API)
│           │   │   ├── createStartupQuestion.ts
│           │   │   ├── createUser.ts
│           │   │   ├── getStartupContent.ts
│           │   │   ├── getStartupDetails.ts
│           │   │   ├── getUserProfile.ts
│           │   │   ├── listStartups.ts
│           │   │   ├── seedStartupCatalog.ts
│           │   │   └── updateMfaPreference.ts
│           │   ├── repositories/     # Acesso ao Firestore
│           │   │   ├── startupRepository.ts
│           │   │   └── userRepository.ts
│           │   ├── shared/           # Código reutilizável
│           │   │   ├── auth.ts
│           │   │   ├── constants.ts
│           │   │   ├── firebase.ts
│           │   │   └── validation.ts
│           │   └── types/            # Tipos TypeScript
│           │       └── index.ts
│           ├── exchange/             # Módulo do balcão (em desenvolvimento)
│           │   ├── handlers/
│           │   ├── repositories/
│           │   ├── shared/
│           │   └── types/
│           └── __tests__/            # Testes unitários (Jest)
│               └── startups/
│                   ├── shared/
│                   ├── types/
│                   └── repositories/
│
├── mobile/                           # Aplicação Flutter
│   ├── pubspec.yaml                  # Dependências Flutter
│   ├── assets/images/                # Imagens (logo)
│   └── lib/
│       ├── main.dart                 # Entry point do app
│       ├── firebase_options.dart     # Config Firebase (gerado)
│       └── screens/
│           ├── login_screen.dart
│           ├── register_screen.dart
│           ├── forgot_password_screen.dart
│           ├── home_screen.dart
│           ├── catalog_screen.dart
│           ├── startup_details_screen.dart
│           ├── profile_screen.dart
│           ├── wallet_screen.dart
│           ├── investment_screen.dart
│           └── investment_confirm_screen.dart
│
├── documentos/                       # Documentação do projeto
│   ├── escopo.md
│   ├── aula6.md
│   └── resumoPDF.md
│
├── .gitignore
└── README.md
```

---

## Arquitetura do Backend

O backend segue o padrão TDD com separação de responsabilidades:

```
Flutter (app) → Cloud Function (handler) → Repository → Firestore
```

* **handlers/** — recebem chamadas do Flutter, validam dados e autenticação
* **repositories/** — únicos que acessam o Firestore (leitura e escrita)
* **shared/** — código reutilizável (auth, validação, constantes, config Firebase)
* **types/** — definição dos tipos de dados (TypeScript)

---

## Cloud Functions Disponíveis

| Function | Descrição |
|----------|-----------|
| `listStartups` | Lista startups com filtro por estágio e busca por texto |
| `getStartupDetails` | Retorna detalhes completos de uma startup |
| `getStartupContent` | Retorna conteúdos públicos (sumário, vídeos, sócios, perguntas) |
| `createStartupQuestion` | Cria pergunta pública ou privada para uma startup |
| `seedStartupCatalog` | Popula o banco com startups de demonstração |
| `createUser` | Salva dados do usuário (nome, CPF, telefone) no Firestore |
| `getUserProfile` | Retorna dados do perfil do usuário |
| `updateMfaPreference` | Atualiza preferência de autenticação multifator |

---

## Como Executar o Projeto

### 1. Clonar o repositório

```bash
git clone https://github.com/DaniMikie/ES-PI3-2026-T1-G31.git
```

### 2. Backend — Instalar dependências e buildar

```bash
cd backend/functions
npm install
npm run build
```

### 3. Backend — Rodar testes

```bash
npm run test
```

### 4. Backend — Deploy para o Firebase

```bash
cd backend
firebase login
firebase deploy --only functions
```

### 5. Mobile — Instalar dependências

```bash
cd mobile
flutter pub get
```

### 6. Mobile — Rodar o app

```bash
flutter run
```

Requer emulador Android (Android Studio) ou dispositivo físico conectado via USB.

---

## Dados no Firebase

### Firestore
* Coleção `startups` — 5 startups cadastradas (GreenPulse, MedConnect, AgroSmart, EduFlex, FinToken)
* Subcoleção `startups/{id}/questions` — perguntas dos usuários
* Subcoleção `startups/{id}/investors` — investidores de cada startup
* Coleção `users` — dados dos usuários (nome, CPF, telefone)

### Authentication
* Email/Password habilitado

---

## Integrantes

* Ana Luísa Maso Mafra – 25007997
* Daniela Mikie Kikuchi Gonçalves – 25003068
* Felipe Nasser Coelho Moussa – 25004922
* Rafaela Jacobsen Braga – 25004280
* Kauan Aurelio Lasmar Dias – 25001590

---

## Disciplina

**Projeto Integrador 3**
Curso de **Engenharia de Software**
**PUC-Campinas – 2026**
