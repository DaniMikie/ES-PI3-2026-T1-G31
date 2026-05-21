/**
 * Tela Balcão — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';

class BalcaoScreen extends StatefulWidget {
  const BalcaoScreen({super.key});

  @override
  State<BalcaoScreen> createState() => _BalcaoScreenState();
}

class _BalcaoScreenState extends State<BalcaoScreen> {
  final _functions = FirebaseFunctions.instance;
  final _searchController = TextEditingController();
  int _tabIndex = 0; // 0 = Tokens disponíveis, 1 = Anunciar seus tokens
  List<Map<String, dynamic>> _startups = [];
  List<Map<String, dynamic>> _myPositions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Carrega startups
      final startupsCallable = _functions.httpsCallable('listStartups');
      final startupsResult = await startupsCallable.call({'stage': '', 'search': _searchController.text.trim()});
      final startupsData = Map<String, dynamic>.from(startupsResult.data as Map);
      final startups = List<Map<String, dynamic>>.from(
        (startupsData['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      // Carrega posicoes do usuario
      final walletCallable = _functions.httpsCallable('getWallet');
      final walletResult = await walletCallable.call();
      final walletData = Map<String, dynamic>.from(walletResult.data as Map);
      final innerData = Map<String, dynamic>.from(walletData['data'] as Map? ?? walletData);
      final positions = List<Map<String, dynamic>>.from(
        (innerData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      print('Balcao positions: $positions');
      print('Startups ids: ${startups.map((s) => s['id']).toList()}');

      if (mounted) setState(() { _startups = startups; _myPositions = positions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStartups() async {
    _loadData();
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'nova': return 'Nova';
      case 'em_operacao': return 'Em operação';
      case 'em_expansao': return 'Em expansão';
      default: return stage;
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

  void _openBuyScreen(Map<String, dynamic> startup) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => _BalcaoComprarScreen(startup: startup),
    ));
  }

  void _openSellScreen(Map<String, dynamic> startup) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => _BalcaoVenderScreen(startup: startup),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(child: Image.asset('assets/images/logo.png', width: 180)),
              const SizedBox(height: 20),
              Text(
                _tabIndex == 0 ? 'Comprar tokens' : 'Anunciar tokens',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 4),
              Text(
                _tabIndex == 0 ? 'Escolha um modo para negociar seus tokens' : 'Escolha um modo para anunciar seus tokens',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Tabs
              Row(
                children: [
                  _buildTab('Tokens disponíveis', 0),
                  const SizedBox(width: 8),
                  _buildTab('Anunciar seus tokens', 1),
                ],
              ),
              const SizedBox(height: 16),
              // Busca
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadStartups(),
                decoration: InputDecoration(
                  hintText: 'Buscar startups',
                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _loadStartups),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tabIndex == 0 ? 'Clique na startup para saber mais informações' : 'Clique na startup para selecioná-la',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              // Lista
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                    : Builder(builder: (context) {
                        // Na aba "Anunciar", mostra só startups que o usuario tem tokens
                        final listaExibida = _tabIndex == 1
                            ? _startups.where((s) => _myPositions.any((p) => p['startupId'] == s['id'])).toList()
                            : _startups;

                        if (listaExibida.isEmpty) {
                          return Center(child: Text(
                            _tabIndex == 0 ? 'Nenhuma startup encontrada' : 'Voce nao possui tokens para anunciar',
                            style: const TextStyle(color: Colors.grey),
                          ));
                        }

                        return ListView.separated(
                        itemCount: listaExibida.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = listaExibida[index];
                          final stage = s['stage'] as String? ?? '';
                          final priceCents = s['currentTokenPriceCents'] as int? ?? 0;
                          final totalTokens = s['totalTokensIssued'] as int? ?? 0;
                          final name = s['name'] as String? ?? '';
                          final tags = List<String>.from(s['tags'] ?? []);
                          final logo = name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'S';

                          return GestureDetector(
                            onTap: () => _tabIndex == 0 ? _openBuyScreen(s) : _openSellScreen(s),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(8)),
                                        alignment: Alignment.center,
                                        child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Text(tags.isNotEmpty ? tags.first : '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _stageColor(stage), borderRadius: BorderRadius.circular(12)),
                                        child: Text(_stageLabel(stage), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('$totalTokens Tokens disponíveis para compra', style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32))),
                                  Text('Valor atual do token: R\$ ${(priceCents / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildTab(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.black : Colors.grey.shade400),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}


// ─── Tela Comprar Tokens ─────────────────────────────────────────

class _BalcaoComprarScreen extends StatefulWidget {
  final Map<String, dynamic> startup;
  const _BalcaoComprarScreen({required this.startup});

  @override
  State<_BalcaoComprarScreen> createState() => _BalcaoComprarScreenState();
}

class _BalcaoComprarScreenState extends State<_BalcaoComprarScreen> {
  final _qtyController = TextEditingController();
  double _valorReais = 0;

  String get _name => widget.startup['name'] as String? ?? '';
  int get _priceCents => widget.startup['currentTokenPriceCents'] as int? ?? 0;
  int get _totalTokens => widget.startup['totalTokensIssued'] as int? ?? 0;
  String get _stage => widget.startup['stage'] as String? ?? '';
  String get _startupId => widget.startup['id'] as String? ?? '';

  void _onQtyChanged(String value) {
    final qty = int.tryParse(value) ?? 0;
    setState(() => _valorReais = qty * _priceCents / 100);
  }

  void _efetuarCompra() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) return;

    // Verifica saldo antes de pedir senha
    try {
      final walletCallable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final walletResult = await walletCallable.call();
      final walletData = Map<String, dynamic>.from(walletResult.data as Map);
      final innerData = Map<String, dynamic>.from(walletData['data'] as Map? ?? walletData);
      final balanceCents = innerData['balanceCents'] as int? ?? 0;
      final custoTotal = qty * _priceCents;

      if (balanceCents < custoTotal) {
        _showSaldoInsuficiente();
        return;
      }
    } catch (e) {
      // Se falhar a verificacao, deixa o backend validar
    }

    _showAuthDialog(qty);
  }

  void _showAuthDialog(int quantity) {
    final senhaController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Autenticação'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Digite sua senha para realizar a compra', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (erro != null)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextField(controller: senhaController, obscureText: true, enabled: !loading, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), hintText: '••••••••')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (senhaController.text.isEmpty) { setDialogState(() => erro = 'Informe sua senha'); return; }
                  setDialogState(() { loading = true; erro = null; });
                  try {
                    final user = FirebaseAuth.instance.currentUser!;
                    await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: senhaController.text));
                    final callable = FirebaseFunctions.instance.httpsCallable('buyTokens');
                    await callable.call({'startupId': _startupId, 'quantity': quantity});
                    Navigator.pop(dialogContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compra realizada! $quantity tokens'), backgroundColor: const Color(0xFF2E7D32)));
                      Navigator.pop(context);
                    }
                  } on FirebaseAuthException catch (_) {
                    setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                  } on FirebaseFunctionsException catch (e) {
                    Navigator.pop(dialogContext);
                    if (mounted) _showSaldoInsuficiente();
                  } catch (e) {
                    setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaldoInsuficiente() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Você não possui\nsaldo suficiente', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 12),
            const Text('Quer saber quanto possui?', style: TextStyle(color: Colors.grey)),
            GestureDetector(
              onTap: () { Navigator.pop(ctx); Navigator.pop(context); },
              child: const Text('Clique para consultar sua carteira →', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, side: const BorderSide(color: Colors.grey)),
              child: const Text('Voltar para o balcão'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = _name.length >= 2 ? _name.substring(0, 2).toUpperCase() : 'S';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 22)),
                  const SizedBox(width: 12),
                  Image.asset('assets/images/logo.png', width: 150),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Comprar tokens', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              const SizedBox(height: 20),
              // Startup info
              Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 20),
              Text('$_totalTokens Tokens disponíveis', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              Text('Valor atual do token: R\$ ${(_priceCents / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StartupDetailsScreen(startupId: _startupId, startupName: _name))),
                child: const Text('Quer saber mais informações? Ir para a startup →', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 28),
              const Text('Quantia de tokens desejada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Digite a quantidade de tokens que deseja', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                onChanged: _onQtyChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '010',
                  suffixText: 'Tokens',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Valor em reais:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_valorReais.toStringAsFixed(2).replaceAll('.', ','), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('reais', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _efetuarCompra,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text('Efetuar compra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tela Anunciar/Vender Tokens ─────────────────────────────────

class _BalcaoVenderScreen extends StatefulWidget {
  final Map<String, dynamic> startup;
  const _BalcaoVenderScreen({required this.startup});

  @override
  State<_BalcaoVenderScreen> createState() => _BalcaoVenderScreenState();
}

class _BalcaoVenderScreenState extends State<_BalcaoVenderScreen> {
  final _qtyController = TextEditingController();
  double _valorReais = 0;

  String get _name => widget.startup['name'] as String? ?? '';
  int get _priceCents => widget.startup['currentTokenPriceCents'] as int? ?? 0;
  int get _totalTokens => widget.startup['totalTokensIssued'] as int? ?? 0;
  String get _startupId => widget.startup['id'] as String? ?? '';

  void _onQtyChanged(String value) {
    final qty = int.tryParse(value) ?? 0;
    setState(() => _valorReais = qty * _priceCents / 100);
  }

  void _efetuarVenda() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) return;

    // Verifica se tem tokens suficientes antes de pedir senha
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final positions = List<Map<String, dynamic>>.from(
        (innerData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      final position = positions.where((p) => p['startupId'] == _startupId).toList();
      final userQty = position.isNotEmpty ? (position.first['quantity'] as int? ?? 0) : 0;

      if (userQty < qty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voce possui apenas $userQty tokens desta startup'), backgroundColor: Colors.red));
        return;
      }
    } catch (e) {
      // Se falhar, deixa o backend validar
    }

    _showAuthDialog(qty);
  }

  void _showAuthDialog(int quantity) {
    final senhaController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Autenticação'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Digite sua senha para realizar a venda', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (erro != null)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextField(controller: senhaController, obscureText: true, enabled: !loading, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), hintText: '••••••••')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (senhaController.text.isEmpty) { setDialogState(() => erro = 'Informe sua senha'); return; }
                  setDialogState(() { loading = true; erro = null; });
                  try {
                    final user = FirebaseAuth.instance.currentUser!;
                    await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: senhaController.text));
                    final callable = FirebaseFunctions.instance.httpsCallable('sellTokens');
                    await callable.call({'startupId': _startupId, 'quantity': quantity});
                    Navigator.pop(dialogContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Venda realizada! $quantity tokens'), backgroundColor: const Color(0xFF2E7D32)));
                      Navigator.pop(context);
                    }
                  } on FirebaseAuthException catch (_) {
                    setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                  } on FirebaseFunctionsException catch (e) {
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Tokens insuficientes'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = _name.length >= 2 ? _name.substring(0, 2).toUpperCase() : 'S';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 22)),
                  const SizedBox(width: 12),
                  Image.asset('assets/images/logo.png', width: 150),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Anunciar tokens', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 20),
              Text('$_totalTokens Tokens disponíveis', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              Text('Valor atual do token: R\$ ${(_priceCents / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StartupDetailsScreen(startupId: _startupId, startupName: _name))),
                child: const Text('Quer saber mais informações? Ir para a startup →', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 28),
              const Text('Quantia de tokens a ser anunciada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Digite a quantidade de tokens a ser vendida', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                onChanged: _onQtyChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '010',
                  suffixText: 'Tokens',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Valor em reais:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_valorReais.toStringAsFixed(2).replaceAll('.', ','), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('reais', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _efetuarVenda,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text('Efetuar anuncio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
