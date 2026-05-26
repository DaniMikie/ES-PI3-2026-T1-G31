// Autora: Ana Luisa Maso Mafra - RA: 25007997
// Integracao: Daniela Mikie Kikuchi Goncalves - RA: 25003068

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';

class BuyScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double tokenPrice;
  final int totalTokens;
  final String stage;
  final List<String> tags;

  const BuyScreen({super.key, required this.startupId, required this.startupName, required this.tokenPrice, required this.totalTokens, required this.stage, required this.tags});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  int quantity = 0;
  double get totalValue => quantity * widget.tokenPrice;

  List<Map<String, dynamic>> _offers = [];
  bool _loadingOffers = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('listOffers');
      final result = await callable.call({'startupId': widget.startupId});
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final offers = List<Map<String, dynamic>>.from(
        (innerData['offers'] as List?)?.map((o) => Map<String, dynamic>.from(o as Map)) ?? [],
      );
      if (mounted) setState(() { _offers = offers; _loadingOffers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingOffers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logo = widget.startupName.length >= 2 ? widget.startupName.substring(0, 2).toUpperCase() : 'S';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/images/logo.png', width: 180),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comprar tokens', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.tags.isNotEmpty ? widget.tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('${widget.totalTokens} Tokens disponiveis', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            Text('Valor atual do token: R\$ ${widget.tokenPrice.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StartupDetailsScreen(startupId: widget.startupId, startupName: widget.startupName))),
              child: const Row(children: [
                Text('Quer saber mais informacoes? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Ir para a startup', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                Icon(Icons.arrow_forward, size: 14, color: Colors.green),
              ]),
            ),
            const SizedBox(height: 24),

            // Compra direta
            const Text('Compra direta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Compre pelo preco atual da startup', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: '10', suffixText: 'Tokens', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
              onChanged: (v) => setState(() => quantity = int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(20)),
              child: Center(child: Text('R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: quantity > 0 ? _efetuarCompra : null,
                child: const Text('Comprar direto', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),

            // Ofertas de investidores
            const Text('Ofertas de investidores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Compre de outros investidores pelo preco deles', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            _buildOffersList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersList() {
    if (_loadingOffers) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.green)));
    }
    if (_offers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: const Text('Nenhuma oferta disponivel no momento', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: _offers.map((offer) {
        final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
        final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
        final priceReais = priceCents / 100;
        final totalReais = qty * priceReais;
        final offerId = offer['id'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$qty tokens a R\$ ${priceReais.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Total: R\$ ${totalReais.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _aceitarOferta(offerId, qty, priceReais),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Comprar', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _aceitarOferta(String offerId, int qty, double priceReais) {
    final senhaController = TextEditingController();
    bool senhaVisivel = false;
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirmar compra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$qty tokens a R\$ ${priceReais.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
                  if (erro != null) Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  TextField(
                    controller: senhaController,
                    obscureText: !senhaVisivel,
                    enabled: !loading,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(senhaVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setDialogState(() => senhaVisivel = !senhaVisivel),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: loading ? null : () async {
                        if (senhaController.text.isEmpty) { setDialogState(() => erro = 'Informe sua senha'); return; }
                        setDialogState(() { loading = true; erro = null; });
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: senhaController.text));
                          final callable = FirebaseFunctions.instance.httpsCallable('acceptOffer');
                          await callable.call({'offerId': offerId});
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compra realizada! $qty tokens'), backgroundColor: Colors.green));
                            _loadOffers();
                          }
                        } on FirebaseAuthException catch (_) {
                          setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                        } on FirebaseFunctionsException catch (e) {
                          setDialogState(() { erro = e.message ?? 'Erro na compra'; loading = false; });
                        } catch (_) {
                          setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                        }
                      },
                      child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _efetuarCompra() async {
    try {
      final walletCallable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final walletResult = await walletCallable.call();
      final walletData = Map<String, dynamic>.from(walletResult.data as Map);
      final innerData = Map<String, dynamic>.from(walletData['data'] as Map? ?? walletData);
      final rawBalance = innerData['balanceCents'];
      final balanceCents = rawBalance is int ? rawBalance : (rawBalance is num ? rawBalance.toInt() : 0);
      final costCents = (quantity * widget.tokenPrice * 100).round();
      if (balanceCents < costCents) {
        if (mounted) _showInsuficiente();
        return;
      }
    } catch (_) {}

    _showAuthDialogCompra();
  }

  void _showAuthDialogCompra() {
    final senhaController = TextEditingController();
    bool senhaVisivel = false;
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Autenticacao', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Digite sua senha para realizar a compra', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),
                  if (erro != null) Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  TextField(
                    controller: senhaController,
                    obscureText: !senhaVisivel,
                    enabled: !loading,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(senhaVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setDialogState(() => senhaVisivel = !senhaVisivel),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: loading ? null : () async {
                        if (senhaController.text.isEmpty) { setDialogState(() => erro = 'Informe sua senha'); return; }
                        setDialogState(() { loading = true; erro = null; });
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: senhaController.text));
                          final callable = FirebaseFunctions.instance.httpsCallable('buyTokens');
                          await callable.call({'startupId': widget.startupId, 'quantity': quantity});
                          Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compra realizada! $quantity tokens de ${widget.startupName}'), backgroundColor: Colors.green));
                            Navigator.pop(context);
                          }
                        } on FirebaseAuthException catch (_) {
                          setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                        } on FirebaseFunctionsException catch (e) {
                          Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            if (e.code == 'failed-precondition' || (e.message ?? '').toLowerCase().contains('saldo')) {
                              _showInsuficiente();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Erro na compra'), backgroundColor: Colors.red));
                            }
                          }
                        } catch (_) {
                          setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                        }
                      },
                      child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInsuficiente() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Saldo insuficiente', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Voce nao possui saldo suficiente para esta compra. Adicione saldo na sua carteira.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
