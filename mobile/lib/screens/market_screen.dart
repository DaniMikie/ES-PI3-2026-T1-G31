// Autora: Ana Luisa Maso Mafra - RA: 25007997
// Integracao: Daniela Mikie Kikuchi Goncalves - RA: 25003068

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'buy_screen.dart';
import 'sell_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _functions = FirebaseFunctions.instance;
  bool isBuyMode = true;
  List<Map<String, dynamic>> _startups = [];
  List<String> _myStartupIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final callable = _functions.httpsCallable('listStartups');
      final result = await callable.call({'stage': '', 'search': ''});
      final data = Map<String, dynamic>.from(result.data as Map);
      final startups = List<Map<String, dynamic>>.from(
        (data['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      // Busca posicoes do usuario
      final walletCallable = _functions.httpsCallable('getWallet');
      final walletResult = await walletCallable.call();
      final walletData = Map<String, dynamic>.from(walletResult.data as Map);
      final innerData = Map<String, dynamic>.from(walletData['data'] as Map? ?? walletData);
      final positions = List<Map<String, dynamic>>.from(
        (innerData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      final myIds = positions.map((p) => p['startupId'] as String).toList();

      if (mounted) setState(() { _startups = startups; _myStartupIds = myIds; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStartups() async {
    _loadData();
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'nova': return Colors.green.shade200;
      case 'em_operacao': return Colors.blue.shade200;
      case 'em_expansao': return Colors.red.shade200;
      default: return Colors.grey.shade200;
    }
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'nova': return 'Nova';
      case 'em_operacao': return 'Em operacao';
      case 'em_expansao': return 'Em expansao';
      default: return stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset('assets/images/logo.png', width: 180)),
              const SizedBox(height: 30),
              Text(
                isBuyMode ? 'Comprar tokens' : 'Anunciar tokens',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 5),
              Text(
                isBuyMode ? 'Escolha um modo para negociar seus tokens' : 'Escolha um modo para anunciar seus tokens',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isBuyMode = true),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(color: isBuyMode ? Colors.black : Colors.grey.shade300, borderRadius: BorderRadius.circular(30)),
                        child: Center(child: Text('Tokens disponiveis', style: TextStyle(color: isBuyMode ? Colors.white : Colors.black, fontSize: 13))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isBuyMode = false),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(color: !isBuyMode ? Colors.black : Colors.grey.shade300, borderRadius: BorderRadius.circular(30)),
                        child: Center(child: Text('Anunciar seus tokens', style: TextStyle(color: !isBuyMode ? Colors.white : Colors.black, fontSize: 13))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar startups',
                  suffixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBuyMode ? 'Clique na startup para saber mais informacoes' : 'Clique na startup para seleciona-la',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : Builder(builder: (context) {
                        final lista = isBuyMode ? _startups : _startups.where((s) => _myStartupIds.contains(s['id'])).toList();
                        if (lista.isEmpty) return Center(child: Text(isBuyMode ? 'Nenhuma startup encontrada' : 'Voce nao possui tokens para anunciar', style: const TextStyle(color: Colors.grey)));
                        return ListView.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final s = lista[index];
                          final name = s['name'] as String? ?? '';
                          final stage = s['stage'] as String? ?? '';
                          final priceCents = s['currentTokenPriceCents'] is num ? (s['currentTokenPriceCents'] as num).toInt() : 0;
                          final totalTokens = s['totalTokensIssued'] is num ? (s['totalTokensIssued'] as num).toInt() : 0;
                          final tags = List<String>.from(s['tags'] ?? []);
                          final logo = name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'S';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => isBuyMode
                                    ? BuyScreen(startupId: s['id'] as String, startupName: name, tokenPrice: priceCents / 100, totalTokens: totalTokens, stage: stage, tags: tags)
                                    : SellScreen(startupId: s['id'] as String, startupName: name, tokenPrice: priceCents / 100, totalTokens: totalTokens, stage: stage, tags: tags),
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 55, height: 55,
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(14)),
                                    child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                Text(tags.isNotEmpty ? tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                              ],
                                            )),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                              decoration: BoxDecoration(color: _stageColor(stage), borderRadius: BorderRadius.circular(20)),
                                              child: Text(_stageLabel(stage), style: const TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isBuyMode ? '$totalTokens Tokens disponiveis para compra' : '$totalTokens Tokens',
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Valor atual do token: R\$ ${(priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
