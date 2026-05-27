// Autora: Ana Luisa Maso Mafra - RA: 25007997
// Integracao: Daniela Mikie Kikuchi Goncalves - RA: 25003068

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'buy_screen.dart';
import 'sell_screen.dart';

// Enum para os três modos do balcão
enum MarketMode { buy, sell, myOffers }

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _functions = FirebaseFunctions.instance;

  MarketMode _mode = MarketMode.buy;
  List<Map<String, dynamic>> _startups = [];
  List<String> _myStartupIds = [];
  List<Map<String, dynamic>> _myOffers = [];
  bool _loading = true;
  bool _loadingMyOffers = false;
  String _searchQuery = '';

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

  Future<void> _loadMyOffers() async {
    setState(() => _loadingMyOffers = true);
    try {
      final callable = _functions.httpsCallable('listMyOffers');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final offers = List<Map<String, dynamic>>.from(
        (innerData['offers'] as List?)?.map((o) => Map<String, dynamic>.from(o as Map)) ?? [],
      );
      if (mounted) setState(() { _myOffers = offers; _loadingMyOffers = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMyOffers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar anúncios: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onModeChanged(MarketMode mode) {
    setState(() => _mode = mode);
    if (mode == MarketMode.myOffers) {
      _loadMyOffers();
    }
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
      case 'em_operacao': return 'Em operação';
      case 'em_expansao': return 'Em expansão';
      default: return stage;
    }
  }

  String _formatMoney(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  List<Map<String, dynamic>> get _filteredStartups {
    final base = _mode == MarketMode.sell
        ? _startups.where((s) => _myStartupIds.contains(s['id'])).toList()
        : _startups;
    if (_searchQuery.isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final tags = List<String>.from(s['tags'] ?? []).map((t) => t.toLowerCase()).toList();
      return name.contains(q) || tags.any((t) => t.contains(q));
    }).toList();
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
              const SizedBox(height: 20),

              // Título dinâmico
              Text(
                _mode == MarketMode.buy
                    ? 'Comprar tokens'
                    : _mode == MarketMode.sell
                        ? 'Anunciar tokens'
                        : 'Meus anúncios',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 5),
              Text(
                _mode == MarketMode.buy
                    ? 'Escolha uma startup para ver as ofertas disponíveis'
                    : _mode == MarketMode.sell
                        ? 'Selecione a startup para criar seu anúncio de venda'
                        : 'Gerencie e cancele seus anúncios ativos',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Abas
              Row(
                children: [
                  _buildTab('Comprar', MarketMode.buy),
                  const SizedBox(width: 8),
                  _buildTab('Vender', MarketMode.sell),
                  const SizedBox(width: 8),
                  _buildTab('Meus anúncios', MarketMode.myOffers),
                ],
              ),
              const SizedBox(height: 20),

              // Barra de busca (oculta em "Meus anúncios")
              if (_mode != MarketMode.myOffers) ...[
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
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
                  _mode == MarketMode.buy
                      ? 'Toque na startup para ver as ofertas de venda'
                      : 'Toque na startup para criar seu anúncio',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
              ],

              // Conteúdo principal───────────────────────────────────────
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, MarketMode mode) {
    final isActive = _mode == mode;
    // "Meus anúncios" ocupa mais espaço
    final flex = mode == MarketMode.myOffers ? 3 : 2;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_mode == MarketMode.myOffers) return _buildMyOffers();
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    final lista = _filteredStartups;
    if (lista.isEmpty) {
      return Center(
        child: Text(
          _mode == MarketMode.sell
              ? 'Você não possui tokens para anunciar'
              : 'Nenhuma startup encontrada',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _loadData,
      child: ListView.separated(
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _mode == MarketMode.buy
                      ? BuyScreen(
                          startupId: s['id'] as String,
                          startupName: name,
                          tokenPrice: priceCents / 100,
                          totalTokens: totalTokens,
                          stage: stage,
                          tags: tags,
                        )
                      : SellScreen(
                          startupId: s['id'] as String,
                          startupName: name,
                          tokenPrice: priceCents / 100,
                          totalTokens: totalTokens,
                          stage: stage,
                          tags: tags,
                        ),
                ),
              ).then((_) => _loadData()); // Recarrega ao voltar
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
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
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(tags.isNotEmpty ? tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: _stageColor(stage), borderRadius: BorderRadius.circular(20)),
                            child: Text(_stageLabel(stage), style: const TextStyle(fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _mode == MarketMode.buy
                                  ? 'Ver ofertas disponíveis'
                                  : '$totalTokens tokens disponíveis',
                              style: TextStyle(
                                color: _mode == MarketMode.buy ? Colors.green : Colors.grey,
                                fontSize: 13,
                                fontWeight: _mode == MarketMode.buy ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (_mode == MarketMode.buy)
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.green.shade400),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preço de mercado: ${_formatMoney(priceCents / 100)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Aba "Meus anúncios"─────────────────────────────────────────────────
  Widget _buildMyOffers() {
    if (_loadingMyOffers) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_myOffers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Você não tem anúncios ativos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie um anúncio na aba "Vender"',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadMyOffers,
              icon: const Icon(Icons.refresh, color: Colors.green),
              label: const Text('Atualizar', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _loadMyOffers,
      child: ListView.separated(
        itemCount: _myOffers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final offer = _myOffers[index];
          final offerId = offer['id'] as String? ?? '';
          final startupId = offer['startupId'] as String? ?? '';
          final startupName = offer['startupName'] as String?
              ?? _startups.where((s) => s['id'] == startupId).map((s) => s['name'] as String).firstOrNull
              ?? 'Startup';
          final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
          final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
          final status = offer['status'] as String? ?? 'active';
          final logo = startupName.length >= 2 ? startupName.substring(0, 2).toUpperCase() : 'S';

          // Data de criação
          String createdLabel = '';
          final createdAt = offer['createdAt'];
          if (createdAt is Map) {
            final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
            if (seconds is int) {
              final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
              final d = date.day.toString().padLeft(2, '0');
              final m = date.month.toString().padLeft(2, '0');
              createdLabel = '$d/$m/${date.year}';
            }
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '$qty tokens × ${_formatMoney(priceCents / 100)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Text(
                        'Total: ${_formatMoney((priceCents * qty) / 100)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      if (createdLabel.isNotEmpty)
                        Text('Criado em $createdLabel', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                // Botão cancelar
                GestureDetector(
                  onTap: () => _confirmCancelOffer(offerId, startupName, qty, priceCents),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmCancelOffer(String offerId, String startupName, int qty, int priceCents) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar anúncio', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que deseja cancelar este anúncio?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(startupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$qty tokens × ${_formatMoney(priceCents / 100)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Os tokens retornarão para sua carteira.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Manter', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelOffer(offerId);
            },
            child: const Text('Cancelar anúncio', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOffer(String offerId) async {
    try {
      final callable = _functions.httpsCallable('cancelOffer');
      await callable.call({'offerId': offerId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anúncio cancelado. Tokens devolvidos.'), backgroundColor: Colors.black87),
        );
        await _loadMyOffers();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erro ao cancelar'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado ao cancelar'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
