import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _functions = FirebaseFunctions.instance;

  String _periodoSelecionado = 'Mês';
  bool _saldoVisivel = true;

  final List<String> _periodos = ['Dia', 'Semana', 'Mês', 'Ano'];

  double _saldo = 0;
  int _totalStartups = 0;
  int _totalTokens = 0;
  List<Investimento> _investimentos = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final callable = _functions.httpsCallable('getWallet');
      final result = await callable.call();

      final data = Map<String, dynamic>.from(result.data as Map);

      final positions = List<Map<String, dynamic>>.from(
        (data['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );

      if (!mounted) return;

      setState(() {
        _saldo = (data['balanceCents'] ?? 0) / 100;
        _totalStartups = data['totalStartups'] ?? 0;
        _totalTokens = data['totalTokens'] ?? 0;

        _investimentos = positions.map((pos) {
          final startupId = pos['startupId'] as String? ?? '';
          return Investimento(
            startupId: startupId,
            startupNome: startupId,
            logoInicial: startupId.length >= 2 ? startupId.substring(0, 2).toUpperCase() : 'ST',
            quantidadeTokens: pos['quantity'] as int? ?? 0,
            valorTotal: ((pos['totalInvestedCents'] as int? ?? 0) / 100),
            variacaoPercent: 0,
          );
        }).toList();
      });
    } catch (e) {
      print('Erro ao carregar carteira: $e');
    }
  }

  void _toggleSaldoVisivel() {
    setState(() {
      _saldoVisivel = !_saldoVisivel;
    });
  }

  void _verDetalhesInvestimento(Investimento inv) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá, NomeUsuário',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                      const Text(
                        'Seus investimentos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _investimentos.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFEEEEEE),
                        ),
                        itemBuilder: (context, index) {
                          return _ItemInvestimento(
                            investimento: _investimentos[index],
                            onTap: () => _verDetalhesInvestimento(
                              _investimentos[index],
                            ),
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
                    color: positivo ? const Color(0xFF2E7D32) : Colors.red,
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