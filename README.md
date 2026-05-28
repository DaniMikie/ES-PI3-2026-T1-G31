# MesclaInvest

## Sobre o Projeto

O **MesclaInvest** é um aplicativo mobile desenvolvido para a disciplina **Projeto Integrador 3** do curso de **Engenharia de Software da PUC-Campinas**.

A aplicação simula uma plataforma digital de investimento em **startups vinculadas ao Mescla**, permitindo que usuários acompanhem projetos, interajam com empreendedores e realizem **negociações simuladas de tokens**.

---

## Funcionalidades Implementadas

* **Autenticação de usuários** (cadastro, login, recuperação de senha, verificação de email)
* **Autenticação multifator (2FA)** com TOTP via Google Authenticator (QR code)
* **Catálogo de startups** com filtros por estágio e busca por texto
* **Tela detalhada da startup** com abas: A Startup, Os Tokens, Perguntas, Novidades
* **Estrutura societária** com sócios, mentores e conselheiros
* **Vídeos demonstrativos** com player YouTube embutido
* **Perguntas públicas e privadas** para empreendedores (privadas só para investidores)
* **Atualizações e eventos** das startups (aba Novidades)
* **Sumário executivo e plano de negócios**
* **Perfil do usuário** com dados pessoais, alteração de senha e 2FA
* **Carteira simulada** com saldo fictício, adição de crédito e saque
* **Compra de tokens** com validação de saldo, limite de emissão e registro de transação
* **Venda de tokens** com re-autenticação por senha
* **Balcão de ofertas** — anunciar tokens com preço customizado, listar e aceitar ofertas de outros investidores
* **Meus anúncios** — visualizar ofertas criadas, status e opção de cancelar
* **Lógica de valorização** — preço do token recalculado automaticamente (média ponderada)
* **Dashboard com gráfico de linhas** — variação de preço por período (dia/semana/mês/6M/YTD)
* **Variação percentual** por investimento (preço de compra vs preço atual)
* **Tokens disponíveis** — controle de emissão (total emitido - vendidos)
* **Capital captado** — atualizado automaticamente a cada compra
* **Histórico de transações** paginado com "Ver mais"
* **Validação de CPF e telefone** duplicado no cadastro
* **Testes unitários** com Jest (34 testes)

---

## Tecnologias Utilizadas

### Frontend (Mobile)
* **Flutter** / **Dart**
* **youtube_player_flutter** (player de vídeo)
* **qr_flutter** (QR code para 2FA)

### Backend
* **Firebase Functions** (Node.js / TypeScript)
* **otplib** (geração e validação TOTP)

### Banco de Dados
* **Firebase Firestore**

### Autenticação
* **Firebase Authentication** (Email/Password)
* **TOTP** (Google Authenticator) para 2FA

### Ferramentas
* **Git** / **GitHub**
* **Visual Studio Code**
* **Android Studio**
* **Jest** (testes unitários)

---

## Arquitetura do Backend

O backend segue separação de responsabilidades em camadas:

```
Flutter (app) → Cloud Function (handler) → Repository → Firestore
```

* **handlers/** — recebem chamadas do Flutter, validam dados e autenticação
* **repositories/** — únicos que acessam o Firestore (leitura e escrita)
* **shared/** — código reutilizável (auth, validação, constantes, config Firebase)
* **types/** — definição dos tipos de dados (TypeScript)

---

## Cloud Functions Disponíveis

### Módulo Startups (6)

| Function | Descrição |
|----------|-----------|
| `listStartups` | Lista startups com filtro por estágio e busca por texto |
| `getStartupDetails` | Retorna detalhes completos + tokens disponíveis |
| `getStartupContent` | Retorna conteúdos públicos |
| `getStartupUpdates` | Retorna atualizações e eventos da startup |
| `createStartupQuestion` | Cria pergunta pública ou privada |
| `seedStartupCatalog` | Popula o banco com dados de demonstração |

### Módulo Exchange (12)

| Function | Descrição |
|----------|-----------|
| `addCredits` | Adiciona saldo fictício na carteira |
| `getWallet` | Retorna saldo, posições e preço atual dos tokens |
| `buyTokens` | Compra tokens (valida saldo, limite de emissão, atualiza capital) |
| `sellTokens` | Venda direta de tokens pelo preço atual |
| `createOffer` | Cria oferta no balcão com preço customizado |
| `listOffers` | Lista ofertas ativas de uma startup |
| `listMyOffers` | Lista ofertas do próprio usuário |
| `acceptOffer` | Aceita oferta (debita comprador, credita vendedor) |
| `cancelOffer` | Cancela oferta e devolve tokens |
| `listTransactions` | Retorna histórico de transações |
| `getTokenHistory` | Histórico de preço para gráfico da carteira |
| `getStartupTokenHistory` | Histórico de preço para gráfico da startup |

### Módulo Users (9)

| Function | Descrição |
|----------|-----------|
| `createUser` | Cadastra usuário (valida CPF e telefone duplicado) |
| `getUserProfile` | Retorna dados do perfil |
| `updateUserProfile` | Atualiza nome e telefone |
| `updateMfaPreference` | Atualiza preferência de MFA |
| `withdrawCredits` | Saque de saldo com re-autenticação |
| `enableTotp` | Gera secret TOTP e retorna QR code |
| `verifyTotp` | Valida código TOTP (ativação e login) |
| `disableTotp` | Desativa TOTP com confirmação por código |
| `checkTotp` | Verifica se usuário tem TOTP ativo |

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
firebase deploy --only functions,firestore:indexes
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
* Subcoleção `startups/{id}/investors` — posição de tokens dos investidores
* Subcoleção `startups/{id}/updates` — atualizações e eventos
* Coleção `users` — dados dos usuários (nome, CPF, telefone, saldo, TOTP)
* Subcoleção `users/{uid}/transactions` — histórico de transações
* Coleção `offers` — ofertas do balcão de negociação

### Authentication
* Email/Password habilitado
* Verificação de email automática no cadastro

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
