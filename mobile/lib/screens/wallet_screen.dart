/**
 * Tela Carteira — MesclaInvest
 * Autor: [Nome do Autor] | RA: [RA do Autor]
 */

import 'package:flutter/material.dart';

// Modelo de investimento do usuário
class Investimento {
  final String startupId;
  final String startupNome;
  final String logoInicial;
  final int quantidadeTokens;
  final double valorTotal;
  final double variacaoPercent;

  const Investimento({
    required this.startupId,
    required this.startupNome,
    required this.logoInicial,
    required this.quantidadeTokens,
    required this.valorTotal,
    required this.variacaoPercent,
  });
}

// Modelo de ponto do gráfico
class PontoGrafico {
  final String label;
  final double valor;

  const PontoGrafico({required this.label, required this.valor});
}

// Dados simulados (futuramente virão da API/Firebase)
const List<Investimento> _investimentosMock = [
  Investimento(
    startupId: 's1',
    startupNome: 'Startup1',
    logoInicial: 'S1',
    quantidadeTokens: 150,
    valorTotal: 320.00,
    variacaoPercent: 1.2,
  ),
  Investimento(
    startupId: 's2',
    startupNome: 'Startup2',
    logoInicial: 'S2',
    quantidadeTokens: 50,
    valorTotal: 50.00,
    variacaoPercent: -11.5,
  ),
  Investimento(
    startupId: 's3',
    startupNome: 'Startup3',
    logoInicial: 'S3',
    quantidadeTokens: 50,
    valorTotal: 50.00,
    variacaoPercent: 11.5,
  ),
];

// Dados simulados do gráfico por período
const Map<String, List<PontoGrafico>> _dadosGrafico = {
  'Dia': [
    PontoGrafico(label: '08h', valor: 390),
    PontoGrafico(label: '10h', valor: 405),
    PontoGrafico(label: '12h', valor: 398),
    PontoGrafico(label: '14h', valor: 412),
    PontoGrafico(label: '16h', valor: 420),
    PontoGrafico(label: '18h', valor: 418),
  ],
  'Semana': [
    PontoGrafico(label: 'Seg', valor: 380),
    PontoGrafico(label: 'Ter', valor: 392),
    PontoGrafico(label: 'Qua', valor: 385),
    PontoGrafico(label: 'Qui', valor: 400),
    PontoGrafico(label: 'Sex', valor: 410),
    PontoGrafico(label: 'Sab', valor: 418),
  ],
  'Mês': [
    PontoGrafico(label: 'Nov 1', valor: 300),
    PontoGrafico(label: 'Nov 7', valor: 320),
    PontoGrafico(label: 'Nov 14', valor: 310),
    PontoGrafico(label: 'Nov 15', valor: 330),
    PontoGrafico(label: 'Nov 21', valor: 350),
    PontoGrafico(label: 'Nov 30', valor: 420),
  ],
  'Ano': [
    PontoGrafico(label: 'Jan', valor: 200),
    PontoGrafico(label: 'Mar', valor: 250),
    PontoGrafico(label: 'Mai', valor: 280),
    PontoGrafico(label: 'Jul', valor: 310),
    PontoGrafico(label: 'Set', valor: 380),
    PontoGrafico(label: 'Nov', valor: 420),
  ],
};

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _periodoSelecionado = 'Mês';
  bool _saldoVisivel = true;

  final List<String> _periodos = ['Dia', 'Semana', 'Mês', 'Ano'];

  // Saldo e tokens totais (simulados)
  final double _saldo = 1234.00;
  final int _totalStartups = 3;
  final int _totalTokens = 300;

  void _toggleSaldoVisivel() {
    setState(() {
      _saldoVisivel = !_saldoVisivel;
    });
  }

  void _verDetalhesInvestimento(Investimento inv) {
    // TO-DO: NAVEGAÇÃO PARA A TELA DE DETALHES DA STARTUP
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrir detalhes de ${inv.startupNome}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Bloco superior escuro ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saudação
                  const Text(
                    'Olá, NomeUsuário',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Saldo + Card de tokens lado a lado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Saldo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _saldoVisivel
                                  ? 'R\$ ${_saldo.toStringAsFixed(2).replaceAll('.', ',')}'
                                  : 'R\$ ••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _toggleSaldoVisivel,
                              child: Row(
                                children: [
                                  const Text(
                                    'Seu saldo',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _saldoVisivel
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF2E7D32),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card de tokens
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tokens',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_totalStartups startups',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_totalTokens tokens',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bloco branco com scroll ────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título Análise
                      const Text(
                        'Análise',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card do gráfico
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Seletor de período
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _periodos.map((periodo) {
                                final selecionado =
                                    _periodoSelecionado == periodo;
                                return GestureDetector(
                                  onTap: () => setState(
                                          () => _periodoSelecionado = periodo),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: selecionado
                                          ? Colors.black
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      periodo,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: selecionado
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),

                            // Gráfico de barras
                            _GraficoBarras(
                              pontos:
                              _dadosGrafico[_periodoSelecionado] ?? [],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Título Investimentos
                      const Text(
                        'Seus investimentos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Lista de investimentos
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _investimentosMock.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFEEEEEE),
                        ),
                        itemBuilder: (context, index) {
                          return _ItemInvestimento(
                            investimento: _investimentosMock[index],
                            onTap: () => _verDetalhesInvestimento(
                                _investimentosMock[index]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget do gráfico de barras
class _GraficoBarras extends StatelessWidget {
  final List<PontoGrafico> pontos;

  const _GraficoBarras({required this.pontos});

  @override
  Widget build(BuildContext context) {
    if (pontos.isEmpty) return const SizedBox.shrink();

    final maxValor = pontos.map((p) => p.valor).reduce((a, b) => a > b ? a : b);
    final ultimoIndex = pontos.length - 1;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(pontos.length, (index) {
          final ponto = pontos[index];
          final alturaRelativa = ponto.valor / maxValor;
          final isUltimo = index == ultimoIndex;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Barra
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: alturaRelativa,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUltimo
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label
                  Text(
                    ponto.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: isUltimo ? Colors.black : Colors.grey,
                      fontWeight: isUltimo
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Widget de item de investimento na lista
class _ItemInvestimento extends StatelessWidget {
  final Investimento investimento;
  final VoidCallback onTap;

  const _ItemInvestimento({
    required this.investimento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final positivo = investimento.variacaoPercent >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                investimento.logoInicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Nome e tokens
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investimento.startupNome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${investimento.quantidadeTokens} tokens',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Valor e variação
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${investimento.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${positivo ? '+' : ''}${investimento.variacaoPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: positivo
                        ? const Color(0xFF2E7D32)
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}