/**
 * Tela Carteira — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _functions = FirebaseFunctions.instance;

  bool _saldoVisivel = true;
  String _periodoSelecionado = 'Mês';
  final List<String> _periodos = ['Dia', 'Semana', 'Mês', '6 meses', 'YTD'];

  double _saldo = 0;
  int _totalStartups = 0;
  int _totalTokens = 0;
  List<Map<String, dynamic>> _investimentos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final callable = _functions.httpsCallable('getWallet');
      final result = await callable.call();
      print('getWallet result: ${result.data}');
      final data = Map<String, dynamic>.from(result.data as Map);
      final walletData = Map<String, dynamic>.from(data['data'] as Map? ?? data);

      final positions = List<Map<String, dynamic>>.from(
        (walletData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );

      if (!mounted) return;

      setState(() {
        _saldo = (walletData['balanceCents'] ?? 0) / 100;
        _totalStartups = walletData['totalStartups'] ?? 0;
        _totalTokens = walletData['totalTokens'] ?? 0;
        _investimentos = positions;
        _loading = false;
      });
    } catch (e) {
      print('Erro getWallet: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSaldo() => setState(() => _saldoVisivel = !_saldoVisivel);

  void _addCredits() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar saldo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'R\$ ', hintText: '100,00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final raw = controller.text.replaceAll(',', '.');
              final valor = double.tryParse(raw);
              if (valor == null || valor <= 0) return;
              Navigator.pop(context);
              try {
                final callable = _functions.httpsCallable('addCredits');
                await callable.call({'amount': (valor * 100).round()});
                _loadWallet();
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('R\$ ${valor.toStringAsFixed(2)} adicionado!'), backgroundColor: const Color(0xFF2E7D32)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Erro ao adicionar saldo'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : Column(
                children: [
                  // Bloco escuro superior
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $_userName',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
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
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: _toggleSaldo,
                                    child: Row(
                                      children: [
                                        const Text('Saldo disponível', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _saldoVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: Colors.grey, size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tokens', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('$_totalStartups startups', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('$_totalTokens tokens', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Botão adicionar saldo
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addCredits,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('+ Adicionar Saldo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bloco branco inferior
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
                            const Text('Análise', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
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
                                    children: _periodos.map((p) {
                                      final sel = _periodoSelecionado == p;
                                      return GestureDetector(
                                        onTap: () => setState(() => _periodoSelecionado = p),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: sel ? Colors.black : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(p, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  // Placeholder gráfico
                                  SizedBox(
                                    height: 100,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: List.generate(7, (i) {
                                        final h = [40.0, 50.0, 45.0, 55.0, 48.0, 52.0, 80.0][i];
                                        final isLast = i == 6;
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: h,
                                              decoration: BoxDecoration(
                                                color: isLast ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Título investimentos
                            const Text('Seus investimentos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            const SizedBox(height: 16),

                            // Lista de investimentos
                            if (_investimentos.isEmpty)
                              const Center(child: Text('Nenhum investimento ainda', style: TextStyle(color: Colors.grey)))
                            else
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _investimentos.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final inv = _investimentos[index];
                                    final startupId = inv['startupId'] as String? ?? '';
                                    final quantity = inv['quantity'] as int? ?? 0;
                                    final totalCents = inv['totalInvestedCents'] as int? ?? 0;
                                    final logo = startupId.length >= 2 ? startupId.substring(0, 2).toUpperCase() : 'ST';

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(startupId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text('$quantity tokens', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'R\$ ${(totalCents / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
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