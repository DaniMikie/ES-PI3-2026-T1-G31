# Documento de Visão Projeto MesclaInvest

Componente Projeto Integrador 3

Curso de Engenharia de Software - 2026

## 1. 0 que é este documento

Este documento apresenta o escopo e requisitos da proposta do projeto MesclaInvest, que deverá ser implementado na disciplina Projeto Integrador 3 em 2026 no curso de Eng. de Software.

### 1.1. Autor  Prof. Me. Mateus Pereira Dias

### 1.2. Quem deve ler esse documento de visão

Todos os estudantes que estão cursando a disciplina de Projeto Integrador 3 do curso de Engenharia de Software no ano de 2026.

### 1.3. Encontrei um erro ou problema neste documento. 0 que devo fazer?

Contatar seus professores orientadores da disciplina de Projeto Integrador 3 para retirar as suas dúvidas e fazer ajustes caso sejam coerentes e necessários.

### 1.4. Direitos autorais

Este documento está protegido nos termos da Lei $\mathrm{n}^{\circ} 9.610 / 98$ (Lei de Direitos Autorais) .

Seu uso é restrito exclusivamente ao contexto acadêmico da disciplina Projeto Integrador 3 do curso de Engenharia de Software da PUC-Campinas no ano de 2026.

É vedada a reprodução, distribuição, encaminhamento, compartilhamento ou reutilização parcial ou integral deste documento, em formato digital ou impresso, sem autorização formal e expressa do autor.

As ideias, soluções, requisitos, estruturas e textos aqui contidos não poderão ser utilizados fora do contexto acadêmico indicado, inclusive em projetos internos ou externos à Universidade, sem prévia autorização escrita do autor.

Caso este documento tenha sido recebido por pessoa não autorizada ou por meio diverso daquele oficialmente encaminhado, recomenda-se sua imediata exclusão e a comunicação ao autor para esclarecimento da origem do envio.

Solicitações de uso para fins comerciais, institucionais ou quaisquer finalidades externas ao escopo acadêmico deverão ser formalizadas exclusivamente por intermédio de advogado regularmente inscrito na OAB ou por escritório jurídico constituído, com a devida representação do interessado.

Pedidos encaminhados sem representação jurídica formal não serão analisados.
Endereço de e-mail institucional do autor:
mateus.dias@puc-campinas.edu.br

## 2. Contextualização do empreendedorismo na PUC-Campinas

A PUC-Campinas desenvolve, por meio do Mescla, um ecossistema de inovação voltado ao fomento do empreendedorismo universitário. O Mescla atua em múltiplas frentes, incluindo espaço de coworking, programas de pré-aceleração e aceleração, mentoria especializada e suporte ao desenvolvimento de novos negócios e startups.

As startups vinculadas ao ecossistema apresentam diferentes níveis de maturidade e necessidades específicas de capital. Os aportes podem ser provenientes da própria Universidade, de parceiros institucionais, investidores-anjo ou do mercado externo. Ainda assim, um dos principais desafios enfrentados por ambientes de inovação é a captação de recursos em estágios iniciais (pré-seed), etapa essencial para que ideias embrionárias possam evoluir, mesmo sem resultados financeiros imediatos.

Em âmbito internacional, é comum que startups iniciem suas atividades com capital próprio, recursos familiares, investidores-anjo ou fundos de capital de risco. A facilidade desse processo depende significativamente do ambiente regulatório de cada país. Em algumas jurisdições, a captação ocorre com menor burocracia do que no Brasil. No contexto acadêmico da PUC-Campinas, busca-se refletir sobre modelos alternativos que possam estimular o investimento inicial de maneira estruturada e transparente.

Ambientes universitários de inovação enfrentam também o desafio de ampliar a visibilidade dos projetos desenvolvidos internamente. Estudantes, professores, familiares e membros da sociedade muitas vezes não dispõem de mecanismos estruturados para conhecer, acompanhar e eventualmente apoiar financeiramente as iniciativas que surgem no ecossistema.

Nesse cenário, o MesclaInvest surge como proposta acadêmica voltada à simulação de um ambiente digital de investimento, promovendo maior integração entre Universidade e sociedade. A iniciativa busca estimular uma cultura de participação, transparência e responsabilidade no apoio a projetos inovadores desenvolvidos por estudantes.

O objetivo não é substituir modelos regulatórios existentes, mas proporcionar, no âmbito pedagógico, uma reflexão prática sobre novas formas de estruturação e acesso a investimentos em estágios iniciais.

## 3. Blockchain e as plataformas de tokenização

Tecnologias baseadas em blockchain possibilitam, há mais de uma década, a criação e o registro descentralizado de ativos digitais. Uma blockchain pode ser entendida como um banco de dados distribuído, imutável e auditável, no qual transações são registradas de forma pública ou permissionada, dependendo da arquitetura adotada.

Nesse contexto, surge o conceito de tokenização. Tokenizar um ativo significa representá-lo digitalmente por meio de unidades registradas em blockchain. Essas unidades são chamadas de tokens e podem representar direitos econômicos, participação societária, acesso a serviços ou qualquer outro tipo de utilidade previamente definida.

Os tokens podem ser classificados, de maneira simplificada, em duas categorias principais:

Tokens fungíveis: são unidades intercambiáveis entre si, ou seja, cada unidade possui o mesmo valor e as mesmas características que outra da mesma espécie. Um exemplo tradicional é o dinheiro: uma nota de mesmo valor pode ser trocada por
outra sem alterar sua natureza. No universo blockchain, o padrão mais conhecido para criação de tokens fungíveis é o ERC-20, amplamente utilizado na rede Ethereum.

Tokens não fungíveis (NFTs): são unidades únicas e não intercambiáveis entre si. Cada token possui características próprias e identificáveis individualmente. Esse modelo é utilizado para representar ativos digitais exclusivos, como obras de arte digitais, certificados ou itens colecionáveis. Na rede Ethereum, o padrão mais conhecido para esse tipo de token é o ERC-721.

Os padrões (como ERC-20 e ERC-721) são conjuntos de regras técnicas que definem como os tokens devem se comportar dentro da rede, estabelecendo funções mínimas obrigatórias, como transferência, consulta de saldo e verificação de propriedade.

A emissão e o gerenciamento desses tokens ocorrem por meio de contratos inteligentes (smart contracts). Contratos inteligentes são programas executados na blockchain que seguem regras previamente definidas em código. Eles podem determinar, por exemplo:

- Quantidade total de tokens emitidos
- Modelo de distribuição inicial
- Regras de transferência
- Condições de bloqueio ou liberação gradual
- Restrições específicas de uso

A forma como o contrato inteligente é projetado influencia diretamente a estrutura econômica e funcional do token criado. Portanto, a modelagem técnica do contrato é elemento central na definição das características do ativo digital representado.

### 3.1. Motivos para tokenizar uma startup

Startups, em seus estágios iniciais, geralmente demandam capital para desenvolvimento de produtos, validação de mercado e estruturação operacional. A captação de recursos pode ocorrer por diversos meios tradicionais, como investimento-anjo, fundos de venture capital ou participação societária formalizada por contratos.

A tokenização surge como uma alternativa tecnológica de representação digital de participação econômica. Por meio da emissão de tokens, é possível estruturar
unidades digitais que representem direitos previamente definidos em contrato, os quais podem incluir participação econômica, acesso a benefícios ou outras utilidades estabelecidas no modelo do projeto.

Diferentemente de modelos tradicionais de crowdfunding, nos quais a transparência depende essencialmente da governança interna da empresa, a utilização de blockchain permite maior rastreabilidade das transações, uma vez que as transferências de tokens são registradas de forma imutável e auditável.

Por exemplo, caso um empreendedor detenha $100 \%$ dos tokens representativos de determinado projeto e decida transferir parte deles a terceiros, essa movimentação ficará registrada publicamente na rede, permitindo rastreabilidade das participações digitais. Isso pode facilitar a entrada e saída de investidores em um ambiente estruturado, desde que existam regras contratuais claras e mecanismos de governança adequados.

É importante destacar que a simples emissão de tokens não substitui instrumentos jurídicos tradicionais. Em ambientes reais, mecanismos como períodos de bloqueio (lock-up), cláusulas contratuais e exigências regulatórias são fundamentais para evitar práticas abusivas ou descontinuidade indevida do projeto.

Comparativamente aos processos tradicionais de captação, que podem envolver etapas burocráticas e intermediação institucional, a utilização de contratos inteligentes possibilita automatização de regras previamente definidas. Esses contratos podem estabelecer condições de emissão, transferência e limitação de tokens, reduzindo a necessidade de intermediários técnicos na execução das operações.

Do ponto de vista econômico, a aquisição de tokens pode representar uma aposta no desempenho futuro do projeto. 0 valor desses ativos digitais pode variar conforme fatores como evolução do produto, adesão de usuários, geração de receita e percepção de mercado.

Em cenários hipotéticos de crescimento e formalização societária futura, eventuais conversões de participação digital em participação societária tradicional dependeriam de estrutura jurídica adequada e conformidade regulatória. Tais processos não são automáticos e exigem instrumentos contratuais específicos.

Adicionalmente, observa-se internacionalmente o surgimento de fundos e instrumentos financeiros baseados em ativos digitais. No entanto, a regulação e maturidade desse mercado variam significativamente entre países.

No contexto deste projeto acadêmico, a tokenização é tratada como conceito tecnológico e modelo de simulação, não representando proposta de captação real de investimentos ou oferta pública de valores mobiliários.

## 4. O Projeto MesclaInvest

Na disciplina de Projeto Integrador 3, os estudantes desenvolverão uma parte de um ecossistema digital de investimentos baseado na negociação simulada de tokens representativos de startups vinculadas ao Mescla.

O escopo da disciplina contempla a implementação de um aplicativo móvel que permitirá ao usuário:

- Visualizar startups cadastradas no ecossistema
- Consultar informações institucionais e societárias
- Acessar documentos públicos, como sumário executivo e plano de negócios
- Enviar perguntas aos empreendedores
- Acompanhar atualizações e eventos

A interface do aplicativo terá características semelhantes às de uma rede social corporativa, combinadas com elementos de plataformas de relações com investidores, proporcionando um ambiente informativo e interativo.

O componente central do sistema será o balcão de tokens, responsável por simular a compra e venda de participações digitais entre usuários da plataforma. De forma conceitual, o funcionamento se assemelha ao de um aplicativo de corretora de investimentos, permitindo que o investidor realize ofertas de compra ou venda de tokens dentro do ambiente da aplicação.

Os detalhes técnicos de implementação serão especificados na seção de requisitos. Ressalta-se que todas as operações de negociação terão caráter exclusivamente simulado, sem envolvimento de ativos reais ou integração com sistemas financeiros externos.

Aspectos relacionados à governança societária real, controle de distribuição estratégica de tokens, restrições contratuais entre sócios ou mecanismos jurídicos de proteção contra diluição indevida não fazem parte do escopo desta disciplina. Tais elementos pertencem ao contexto de desenvolvimento de produto em ambiente regulado e extrapolam os objetivos pedagógicos do componente curricular.

O foco do projeto está na modelagem técnica da aplicação, na arquitetura de software e na implementação das funcionalidades propostas, proporcionando aos estudantes experiência prática no desenvolvimento de sistemas digitais estruturados.

## 5. Requisitos do MesclaInvest

### 5.1. Autenticação

Para utilizar o MesclaInvest e acessar suas funcionalidades - incluindo navegação pelas startups, envio de perguntas e negociação simulada de tokens - o usuário deverá criar uma conta individual por meio de endereço de e-mail válido.

No momento do cadastro, deverão ser informados obrigatoriamente os seguintes dados:

- Nome completo
- E-mail
- CPF
- Telefone celular
- Senha

O sistema deverá implementar mecanismo de recuperação de senha por meio da funcionalidade “Esqueci minha senha”, com envio de instruções para o e-mail cadastrado.

Não haverá acesso anônimo à plataforma.

Em contextos reais de investimento, o acesso a informações e operações financeiras está sujeito a regulações como KYC (Know Your Customer), que exigem identificação formal do investidor como mecanismo de prevenção à lavagem de dinheiro e outras práticas ilícitas.

A implementação de processos formais de verificação KYC não faz parte do escopo deste projeto acadêmico, sendo mencionada apenas para contextualização conceitual.

### 5.2. Catálogo de startups

O catálogo de startups constitui uma das funcionalidades centrais da aplicação.

O usuário poderá:

- Navegar pelas startups cadastradas
- Visualizar descrição do projeto
- Consultar estrutura societária
- Identificar participação percentual dos sócios
- Verificar volume de capital já aportado (simulado)
- Consultar quantidade total de tokens emitidos
- Visualizar membros do conselho, mentores ou participantes externos (quando aplicável)

As startups deverão ser classificadas conforme estágio de desenvolvimento, permitindo filtros como:

- Nova (ideia recentemente publicada)
- Em operação
- Em expansão

Essa classificação permitirá ao usuário compreender o nível de maturidade e risco associado a cada projeto.

Ao acessar a página detalhada de uma startup, o usuário poderá visualizar:

- Sumário executivo
- Estrutura societária
- Perguntas e respostas públicas
- Vídeos demonstrativos
- Apresentação dos sócios (quando disponível)

Caso o usuário já seja investidor daquela startup, poderá ter acesso a funcionalidades adicionais, como:

- Compra e venda de tokens
- Envio de perguntas privadas ou exclusivas (conforme regras definidas pela equipe)

### 5.3. Compra e venda de tokens - Balcão

A negociação de tokens será inteiramente simulada no contexto deste projeto de graduação.

Integrações reais com meios de pagamento exigiriam constituição jurídica formal, contratos com instituições financeiras autorizadas e conformidade regulatória junto ao Banco Central do Brasil, o que está fora do escopo da disciplina.

No ambiente simulado, o usuário poderá carregar sua carteira digital com saldo fictício em reais, por meio de um mecanismo de simulação de crédito interno, e utilizar esse saldo para adquirir tokens.

A negociação poderá ocorrer:

- Diretamente na página da startup
- Em uma interface específica de ofertas (balcão de negociação)

As transações estarão restritas aos usuários cadastrados na plataforma.

O funcionamento conceitual se assemelha ao de aplicativos de corretoras de investimento, permitindo registro de ofertas de compra e venda dentro do ambiente controlado da aplicação.

### 5.4. Acompanhamento da valorização dos tokens

O investidor poderá acompanhar a variação do valor de seus tokens por meio de painel gráfico (dashboard).

O sistema deverá permitir visualização de variação em diferentes períodos, tais como:

- Diário
- Semanal
- Mensal
- Últimos 6 meses
- YTD (Year to Date)

Os valores serão calculados com base nas transações registradas no sistema simulado.
Cada equipe deverá definir e implementar a lógica de cálculo utilizada para representar variação, tendência ou oscilação de valor. Este item possui caráter avaliativo diferenciado e estimula a aplicação de conceitos matemáticos e estatísticos pertinentes.

### 5.5. Segurança de acesso da conta

O usuário poderá habilitar autenticação multifator (MFA ou 2FA) de forma opcional.
A implementação desse mecanismo deverá ocorrer de maneira funcional no protótipo.
Embora aplicações financeiras reais exijam múltiplas camadas de segurança adicionais (criptografia avançada, monitoramento antifraude, análise comportamental, entre outras), para fins acadêmicos a implementação de MFA será considerada suficiente como mecanismo complementar de segurança.

### 5.6. Não escopo (Projeto Integrador 3)

O projeto a ser desenvolvido na disciplina Projeto Integrador 3 corresponde a uma parte de um sistema conceitualmente mais amplo. Ao término do período letivo, será entregue um protótipo funcional com escopo delimitado, não se tratando de produto final apto para implantação institucional.

Diversas competências técnicas, jurídicas e regulatórias envolvidas em uma plataforma real de tokenização extrapolam os objetivos pedagógicos e o tempo disponível na disciplina. Portanto, os seguintes itens não fazem parte do escopo:

- Integração com meios de pagamento reais, incluindo cartões de crédito, adquirentes, subadquirentes ou instituições financeiras autorizadas;
- Emissão de tokens reais em redes blockchain públicas ou privadas, incluindo implementação de padrões como ERC-20 ou similares;
- Desenvolvimento, auditoria ou implantação de contratos inteligentes (smart contracts) em qualquer blockchain;
- Implementação de linguagem Solidity ou qualquer outra linguagem voltada à programação de contratos inteligentes;
- Versão Web completa da aplicação;
- Implantação em ambiente de produção ou disponibilização pública com finalidade de captação real de recursos.

A negociação de tokens deverá ser integralmente simulada, utilizando registros armazenados em banco de dados (Firebase Firestore), com regras implementadas exclusivamente no backend da aplicação.

0 foco da disciplina está na arquitetura de software, modelagem de dados, desenvolvimento de APIs, implementação de interface mobile e integração entre camadas do sistema.

## 6. Requisitos de ambiente

Os ambientes e tecnologias abaixo são obrigatórios para todas as equipes do Projeto Integrador:

Backend A aplicação deverá possuir backend desenvolvido em:

- Node.js (última versão LTS disponível no início do semestre)
- Linguagem TypeScript e/ou JavaScript

O backend será responsável por simular os dados da plataforma, implementar regras de negócio e disponibilizar APIs para consumo pelo aplicativo mobile. Para citar um exemplo: Não haverá uma interface mobile para cadastro de startups. Os dados do cadastro já deverão existir e serão fornecidos via API (por uma rota) para que o aplicativo mobile possa apresentar.

Frontend (Aplicação Mobile) A interface do usuário deverá ser desenvolvida utilizando:

- Flutter
- Linguagem Dart

Não será aceita implementação em outras tecnologias mobile.

Banco de Dados 0 banco de dados obrigatório será:

- Firebase Firestore (modelo não relacional)

Não será permitida substituição por outros bancos relacionais ou não relacionais.

## Ambientes de Desenvolvimento (IDE)

As equipes deverão utilizar obrigatoriamente uma das seguintes IDEs:

- Microsoft Visual Studio Code
- Android Studio

## Controle de Versão e Repositório

O versionamento de código deverá ser realizado com:

- Git
- Repositório remoto hospedado exclusivamente no GitHub

Não serão aceitos outros serviços de hospedagem de código (como Bitbucket, GitLab ou similares) nem outros sistemas de controle de versão (como Mercurial).

## 7. Regras elementares do Projeto Integrador

### 7.1. Nome do repositório

A equipe deverá criar o repositório no GitHub obedecendo rigorosamente ao seguinte padrão:

ES-PI3-ANO-TURMA-NUMERO-GRUPO

Exemplo: ES-PI3-2026-T2-G03

O nome deverá estar integralmente em letras maiúsculas e seguir exatamente o formato estabelecido.

0 descumprimento do padrão implicará desconto de 1,0 ponto na nota final de cada integrante da equipe.

### 7.2. Armazenamento de código e contribuições dos membros

O código-fonte deverá ser armazenado obrigatoriamente em repositório no GitHub.

Não será aceita a utilização de qualquer outro serviço de hospedagem ou sistema de controle de versão.

A equipe deverá aplicar o conceito de branches para desenvolvimento de funcionalidades. Cada nova funcionalidade deverá ser desenvolvida em branch específica e posteriormente integrada à branch principal (main ou master).

Commits deverão refletir desenvolvimento real e progressivo do projeto.

A avaliação individual considerará a produção efetiva registrada no histórico do repositório.

Membros que não estiverem formalmente adicionados ao repositório desde o início do projeto, serão reprovados for falta de comprometimento com a equipe.

### 7.3. Release de entrega final

Para a entrega final, a equipe deverá criar uma TAG no repositório denominada:
1.0.0-final

A ausência da TAG implicará desconto de 1,0 ponto na nota final de cada integrante.

### 7.4. Arquivo README.md

O repositório deverá conter, obrigatoriamente, um arquivo README.md na raiz do projeto.

0 README deverá apresentar:

- Descrição do projeto
- Nome dos integrantes
- Tecnologias utilizadas
- Instruções claras para execução do sistema em ambiente de testes

A ausência do README até a data de entrega implicará desconto de 1,0 ponto na nota final de cada integrante.

### 7.5. Comentários nos códigos

Cada arquivo do projeto deverá possuir um único autor principal claramente identificado no cabeçalho do arquivo.

A autoria deve refletir responsabilidade técnica predominante sobre aquele artefato. Não será permitido inserir múltiplos nomes como coautores de forma genérica com o objetivo de caracterizar participação coletiva indistinta.

Colaboração entre membros é incentivada, porém a responsabilidade por cada arquivo, ou artefato, deverá ser atribuída a um único integrante, que responderá tecnicamente por sua implementação.

A identificação deverá conter, no mínimo:

- Nome completo do autor
- RA (Registro Acadêmico)

A avaliação individual considerará a coerência entre:

- Autoria declarada nos arquivos
- Histórico de commits no GitHub
- Participação demonstrada nas reuniões de orientação

Arquivos contendo múltiplos autores sem justificativa técnica específica ou com autoria incompatível com o histórico de desenvolvimento poderão ser desconsiderados para fins de avaliação individual.

A individualidade da produção é requisito obrigatório do Projeto Integrador.

### 7.6. Apontamento de esforço

As tarefas deverão ser organizadas obrigatoriamente no GitHub Projects.

Todas as atividades realizadas deverão ser registradas, incluindo estimativa e esforço real empregado.

O uso meramente formal da ferramenta, sem correspondência com o desenvolvimento efetivo do projeto, poderá implicar em desclassificação da equipe antes da banca avaliadora, a critério do docente orientador. Portanto use a ferramenta corretamente desde o início. Sua equipe será cobrada disso.

### 7.7. Participação nas reuniões de orientação

A equipe deverá participar das reuniões periódicas de acompanhamento com o(a) professor(a) da disciplina Projeto Integrador 3.

Cada integrante deverá demonstrar evolução concreta das atividades sob sua responsabilidade.

A ausência injustificada ou a falta de apresentação de resultados poderá resultar em desconto na nota individual de comprometimento.

### 7.8. Convite de participação no repositório

Inicialmente, a equipe deverá convidar apenas os integrantes e o(a) docente orientador(a) para participação no repositório.

Convites adicionais somente deverão ser realizados quando formalmente orientados.

Convites realizados fora das orientações poderão ser desconsiderados para fins de avaliação.

### 7.9. Banca avaliadora

Todos os grupos deverão apresentar o projeto perante banca avaliadora em data e horário previamente divulgados.

0 tempo máximo de apresentação será de 20 minutos, incluindo tempo de preparação (setup).

A condução da apresentação será definida pela banca avaliadora, que poderá iniciar pela demonstração técnica ou por arguição direta.

O sistema deverá estar plenamente funcional no momento da apresentação.
PUC-Campinas - 2026 - Todos os direitos reservados - Página 16

Em caso de falhas técnicas, a equipe terá até 3 minutos para tentativa de resolução.

Não sendo possível restabelecer o funcionamento mínimo necessário, a banca poderá interromper a apresentação e deliberar sobre eventual desclassificação da equipe.

É responsabilidade do grupo realizar testes prévios, preparar plano de contingência e garantir pleno funcionamento do ambiente de demonstração.