# MesclaInvest

## Sobre o Projeto

O **MesclaInvest** é um aplicativo mobile desenvolvido para a disciplina **Projeto Integrador 3** do curso de **Engenharia de Software da PUC-Campinas**.

A aplicação simula uma plataforma digital de investimento em **startups vinculadas ao Mescla**, permitindo que usuários acompanhem projetos, interajam com empreendedores e realizem **negociações simuladas de tokens**.

---

## Funcionalidades

* **Autenticação de usuários**
* **Catálogo de startups**
* **Visualização de informações institucionais**
* **Envio de perguntas para empreendedores**
* **Compra e venda simulada de tokens**
* **Acompanhamento da valorização dos tokens**
* **Segurança da conta (autenticação adicional)**

---

## Tecnologias Utilizadas

### Frontend (Mobile)

* **Flutter**
* **Dart**

### Backend

* **Node.js**
* **JavaScript / TypeScript**

### Banco de Dados

* **Firebase Firestore**

### Ferramentas de Desenvolvimento

* **Git**
* **GitHub**
* **Visual Studio Code**
* **Android Studio**

---

## Estrutura do Projeto

```
    PI3/
│
├── .git/                          # Controle de versão Git
│   ├── hooks/
│   ├── info/
│   ├── logs/
│   ├── objects/
│   ├── refs/
│   └── [arquivos de configuração do Git]
│
├── backend/                       # API Node.js + TypeScript
│   ├── node_modules/             # Dependências instaladas (npm)
│   │   └── [270+ pacotes]
│   │
│   ├── src/                      # Código-fonte
│   │   ├── config/              # Configurações
│   │   ├── controllers/         # Controladores
│   │   ├── middlewares/         # Middlewares
│   │   ├── models/              # Modelos de dados
│   │   ├── routes/              # Rotas da API
│   │   ├── services/            # Serviços/lógica de negócio
│   │   ├── utils/               # Utilitários
│   │   └── server.ts            # Servidor Express inicial configurado
│   │
│   ├── .env                      # Variáveis de ambiente (PORT=3000)
│   ├── .gitignore               # Arquivos ignorados pelo Git
│   ├── package.json             # Dependências e scripts npm
│   ├── package-lock.json        # Lock de versões
│   └── tsconfig.json            # Configuração TypeScript
│
├── database/                     # database
|
├── mobile/                       # Aplicação Flutter
│
├── .gitignore                    # Git ignore raiz
└── README.md                     # Documentação do projeto

```

---

## Como Executar o Projeto

### 1. Clonar o repositório

```bash
git clone https://github.com/seu-usuario/nome-do-repositorio.git
```

---

### 2. Executar o Backend

```bash
cd backend
npm install
npm run dev
```

---

### 3. Executar o Aplicativo Mobile

---

## Integrantes

* Ana Luísa Maso Mafra – RA 25007997
* Daniela Mikie Kikuchi Gonçalves – 25003068
* Felipe Nasser Coelho Moussa – 25004922
* Rafaela Jacobsen Braga – RA
* Kauan Aurelio Lasmar Dias – 25001590

---

## Disciplina

Projeto desenvolvido para a disciplina:

**Projeto Integrador 3**
Curso de **Engenharia de Software**
**PUC-Campinas – 2026**

---
