/**
 * Tela Início — MesclaInvest
 * Autor: [Nome do Autor] | RA: [RA do Autor]
 */

import 'package:flutter/material.dart';

// ── Modelos de dados ────────────────────────────────────────────

class StartupHome {
  final String id;
  final String nome;
  final String categoria;
  final String universidade;
  final String descricao;
  final String estadio; // 'Nova', 'Em operação', 'Em expansão'
  final double capitalCaptado;
  final int totalTokens;
  final double valorPorToken;
  final String logoInicial;

  const StartupHome({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.universidade,
    required this.descricao,
    required this.estadio,
    required this.capitalCaptado,
    required this.totalTokens,
    required this.valorPorToken,
    required this.logoInicial,
  });
}

// ── Dados simulados (futuramente virão da API) ──────────────────

final List<StartupHome> _startupsMock = [
  const StartupHome(
    id: 's1',
    nome: 'Startup1',
    categoria: 'Tecnologia',
    universidade: 'PUC',
    descricao: 'Descrição startup aqui',
    estadio: 'Nova',
    capitalCaptado: 10000,
    totalTokens: 5000,
    valorPorToken: 2.50,
    logoInicial: 'S1',
  ),
  const StartupHome(
    id: 's2',
    nome: 'Startup2',
    categoria: 'Tecnologia',
    universidade: 'PUC',
    descricao: 'Descrição startup aqui',
    estadio: 'Em operação',
    capitalCaptado: 15000,
    totalTokens: 2500,
    valorPorToken: 4.50,
    logoInicial: 'S2',
  ),
  const StartupHome(
    id: 's3',
    nome: 'Startup3',
    categoria: 'Saúde',
    universidade: 'PUC',
    descricao: 'Descrição startup aqui',
    estadio: 'Em expansão',
    capitalCaptado: 22000,
    totalTokens: 8000,
    valorPorToken: 6.00,
    logoInicial: 'S3',
  ),
];

// ── Tela Início ─────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _filtroSelecionado = 'Todas';
  List<StartupHome> _startupsFiltradas = _startupsMock;

  final List<String> _filtros = ['Todas', 'Novas', 'Em operação', 'Em expansão'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _startupsFiltradas = _startupsMock.where((s) {
        final matchTexto = query.isEmpty ||
            s.nome.toLowerCase().contains(query) ||
            s.descricao.toLowerCase().contains(query) ||
            s.categoria.toLowerCase().contains(query);
        final matchEstadio = _filtroSelecionado == 'Todas' ||
            (_filtroSelecionado == 'Novas' && s.estadio == 'Nova') ||
            s.estadio == _filtroSelecionado;
        return matchTexto && matchEstadio;
      }).toList();
    });
  }

  void _onFiltroTap(String filtro) {
    setState(() => _filtroSelecionado = filtro);
    _aplicarFiltros();
  }

  void _onSearchChanged(String _) => _aplicarFiltros();

  void _verDetalhes(StartupHome startup) {
    // TO-DO: NAVEGAÇÃO PARA A TELA DE DETALHES DA STARTUP
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrir detalhes de ${startup.nome}')),
    );
  }

  Color _corEstadio(String estadio) {
    switch (estadio) {
      case 'Nova':
        return const Color(0xFF2E7D32);
      case 'Em operação':
        return const Color(0xFF1565C0);
      case 'Em expansão':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  // Seta voltar (mantida conforme Figma)
                  const Icon(Icons.arrow_back, size: 22),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'MesclaInvest',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // Espaço para equilibrar o ícone da esquerda
                  const SizedBox(width: 22),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Campo de busca ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextFormField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar startups',
                  hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 14),
                  suffixIcon:
                  const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: const BorderSide(
                        color: Color(0xFF2E7D32), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Filtros por estágio ────────────────────────────
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filtros.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filtro = _filtros[index];
                  final selecionado = _filtroSelecionado == filtro;
                  return GestureDetector(
                    onTap: () => _onFiltroTap(filtro),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selecionado
                            ? Colors.black
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        filtro,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selecionado
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Subtítulo e título Destaques ───────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Clique na startup para saber mais',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text(
                'Destaques',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Lista de startups ──────────────────────────────
            Expanded(
              child: _startupsFiltradas.isEmpty
                  ? const Center(
                child: Text(
                  'Nenhuma startup encontrada.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: _startupsFiltradas.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final startup = _startupsFiltradas[index];
                  return _StartupCardHome(
                    startup: startup,
                    corEstadio: _corEstadio(startup.estadio),
                    onTap: () => _verDetalhes(startup),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card de startup ──────────────────────────────────────────────

class _StartupCardHome extends StatelessWidget {
  final StartupHome startup;
  final Color corEstadio;
  final VoidCallback onTap;

  const _StartupCardHome({
    required this.startup,
    required this.corEstadio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Linha superior: avatar + info + badge ──────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    startup.logoInicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Nome, categoria e universidade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startup.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        startup.categoria,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        startup.universidade,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge do estágio
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: corEstadio,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    startup.estadio,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Descrição
            Text(
              startup.descricao,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Divisória
            Divider(color: Colors.grey.shade200, height: 1),

            const SizedBox(height: 12),

            // ── Linha de dados financeiros ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoColuna(
                  valor: 'R\$ ${_formatarCapital(startup.capitalCaptado)}',
                  label: 'Captado',
                ),
                _InfoColuna(
                  valor: '${startup.totalTokens}',
                  label: 'Tokens',
                ),
                _InfoColuna(
                  valor:
                  'R\$ ${startup.valorPorToken.toStringAsFixed(2)}',
                  label: 'Por token',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatarCapital(double valor) {
    if (valor >= 1000) {
      final milhar = valor / 1000;
      return '${milhar % 1 == 0 ? milhar.toInt() : milhar.toStringAsFixed(1)} mil';
    }
    return valor.toStringAsFixed(0);
  }
}

// ── Widget auxiliar de coluna de informação ──────────────────────

class _InfoColuna extends StatelessWidget {
  final String valor;
  final String label;

  const _InfoColuna({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}