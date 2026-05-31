/*
---------- Tela de Balcão ----------
- Autora Principal: Ana Luisa Maso Mafra | RA: 25007997
*/

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'buy_screen.dart';
import 'sell_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  List<String> _startupsWithOffers = [];
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

      // Carrega IDs de startups com ofertas ativas
      List<String> startupsWithOffers = [];
      try {
        final offersCallable = _functions.httpsCallable('listStartupsWithOffers');
        final offersResult = await offersCallable.call();
        final offersData = Map<String, dynamic>.from(offersResult.data as Map);
        final offersInner = Map<String, dynamic>.from(offersData['data'] as Map? ?? offersData);
        startupsWithOffers = List<String>.from(offersInner['startupIds'] as List? ?? []);
      } catch (_) {}

      if (mounted) setState(() { _startups = startups; _myStartupIds = myIds; _startupsWithOffers = startupsWithOffers; _loading = false; });
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
          SnackBar(content: Text("Erro ao carregar anúncios: $e"), backgroundColor: Color(0xFFB30B0E)),
        );
      }
    }
  }

  String get _userDisplayName {
    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    return 'Usuário';
  }
  String get _userInitials {
    final parts = _userDisplayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Widget _buildUserIdentity() {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF2E7D32),
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          child: hasPhoto
              ? null
              : Text(
            _userInitials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Menu do usuário
  void _showUserMenu() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_userDisplayName),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Color(0xFFB30B0E)),
                title: const Text(
                  'Sair da conta',
                  style: TextStyle(color: Color(0xFFB30B0E)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmExit();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Confirmação de saída
  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  void _onModeChanged(MarketMode mode) {
    setState(() => _mode = mode);
    if (mode == MarketMode.myOffers) {
      _loadMyOffers();
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'nova': return const Color(0xFF2E7D32);
      case 'em_operacao': return const Color(0xFF1565C0);
      case 'em_expansao': return Colors.orange.shade700;
      default: return Colors.grey;
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
        : _mode == MarketMode.buy
            ? _startups.where((s) => _startupsWithOffers.contains(s['id'])).toList()
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', width: 180),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: _showUserMenu,
                      child: _buildUserIdentity(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _mode == MarketMode.buy
                    ? 'Comprar tokens'
                    : _mode == MarketMode.sell
                    ? 'Anunciar tokens'
                    : 'Meus anúncios',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _mode == MarketMode.buy
                    ? 'Escolha uma startup para ver as ofertas disponíveis'
                    : _mode == MarketMode.sell
                    ? 'Selecione a startup para criar seu anúncio de venda'
                    : 'Gerencie e cancele seus anúncios ativos',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Abas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildTab('Comprar', MarketMode.buy),
                  const SizedBox(width: 8),
                  _buildTab('Vender', MarketMode.sell),
                  const SizedBox(width: 8),
                  _buildTab('Meus anúncios', MarketMode.myOffers),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Barra de busca (oculta em "Meus anúncios")
            if (_mode != MarketMode.myOffers) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextFormField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar startups',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/icons/magnifier.svg',
                        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _mode == MarketMode.buy
                      ? 'Toque na startup para ver as ofertas de venda'
                      : 'Toque na startup para criar seu anúncio',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Conteúdo principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, MarketMode mode) {
    final isActive = _mode == mode;
    final flex = mode == MarketMode.myOffers ? 3 : 2;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_mode == MarketMode.myOffers) return _buildMyOffers();
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));

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
      color: const Color(0xFF2E7D32),
      onRefresh: _loadData,
      child: ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, _) => const SizedBox(height: 15),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              Text(tags.isNotEmpty ? tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: _stageColor(stage), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _stageLabel(stage),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                color: _mode == MarketMode.buy ? const Color(0xFF2E7D32) : Colors.grey,
                                fontSize: 13,
                                fontWeight: _mode == MarketMode.buy ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (_mode == MarketMode.buy || _mode == MarketMode.sell)
                              Icon(Icons.arrow_forward_ios, size: 12, color: const Color(0xFF2E7D32).withValues(alpha: 0.7)),
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

  // Aba "Meus anúncios"
  Widget _buildMyOffers() {
    if (_loadingMyOffers) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
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
              icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
              label: const Text('Atualizar', style: TextStyle(color: Color(0xFF2E7D32))),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _loadMyOffers,
      child: ListView.separated(
        itemCount: _myOffers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(12)),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                      if (createdLabel.isNotEmpty)
                        Text('Criado em $createdLabel', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                // Botão cancelar (só ativas) ou badge de status
                if (status == 'active')
                  GestureDetector(
                    onTap: () => _confirmCancelOffer(offerId, startupName, qty, priceCents),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade500),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Color(0xFFB30B0E), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: status == 'sold' ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'sold' ? 'Vendido' : 'Cancelado',
                      style: TextStyle(
                        color: status == 'sold' ? const Color(0xFF2E7D32) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
              backgroundColor: Color(0xFFB30B0E),
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
          SnackBar(content: Text(e.message ?? 'Erro ao cancelar'), backgroundColor: Color(0xFFB30B0E)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado ao cancelar'), backgroundColor: Color(0xFFB30B0E)),
        );
      }
    }
  }
}
