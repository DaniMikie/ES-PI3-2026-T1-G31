// Autora: Ana Luisa Maso Mafra - RA: 25007997
// Integracao: Daniela Mikie Kikuchi Goncalves - RA: 25003068

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';

class BuyScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double tokenPrice; // preço de mercado, usado como referência
  final int totalTokens;
  final String stage;
  final List<String> tags;

  const BuyScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.tokenPrice,
    required this.totalTokens,
    required this.stage,
    required this.tags,
  });

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _loadingOffers = true;
  String? _offerError;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() { _loadingOffers = true; _offerError = null; });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('listOffers');
      final result = await callable.call({'startupId': widget.startupId});
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final offers = List<Map<String, dynamic>>.from(
        (innerData['offers'] as List?)?.map((o) => Map<String, dynamic>.from(o as Map)) ?? [],
      );
      // Ordena por menor preço primeiro
      offers.sort((a, b) {
        final pa = a['priceCents'] is num ? (a['priceCents'] as num).toInt() : 0;
        final pb = b['priceCents'] is num ? (b['priceCents'] as num).toInt() : 0;
        return pa.compareTo(pb);
      });
      if (mounted) setState(() { _offers = offers; _loadingOffers = false; });
    } catch (e) {
      if (mounted) setState(() { _offerError = 'Não foi possível carregar as ofertas'; _loadingOffers = false; });
    }
  }

  String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    final digits = intPart.startsWith('-') ? intPart.substring(1) : intPart;
    if (intPart.startsWith('-')) buffer.write('-');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'R\$ $buffer,$decPart';
  }
  @override
  Widget build(BuildContext context) {
    final logo = widget.startupName.length >= 2
        ? widget.startupName.substring(0, 2).toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/images/logo.png', width: 150),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: _loadOffers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comprar tokens',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha uma oferta de vendedor para comprar',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Card da startup
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(widget.tags.isNotEmpty ? widget.tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                    ),
                    // Preço de mercado como referência
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Preço mercado', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(
                        _formatMoney(widget.tokenPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StartupDetailsScreen(startupId: widget.startupId, startupName: widget.startupName)),
                ),
                child: const Row(children: [
                  Text('Quer saber mais informações? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Ir para a startup', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.green),
                ]),
              ),
              const SizedBox(height: 28),

              // Lista de ofertas─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ofertas disponíveis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (!_loadingOffers)
                    Text(
                      '${_offers.length} ${_offers.length == 1 ? 'oferta' : 'ofertas'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Ordenadas por menor preço. Puxe para atualizar.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),

              if (_loadingOffers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
              else if (_offerError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(children: [
                      Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 8),
                      Text(_offerError!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _loadOffers, child: const Text('Tentar novamente', style: TextStyle(color: Colors.green))),
                    ]),
                  ),
                )
              else if (_offers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(children: [
                      Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhuma oferta disponível no momento',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Volte mais tarde ou tente outra startup',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    final offerId = offer['id'] as String? ?? '';
                    final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
                    final pricePerToken = priceCents / 100;
                    final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
                    final totalCents = priceCents * qty;
                    final sellerName = offer['sellerName'] as String? ?? 'Vendedor';

                    // Calcula variação em relação ao preço de mercado
                    final marketCents = (widget.tokenPrice * 100).round();
                    final diff = marketCents > 0 ? ((priceCents - marketCents) / marketCents) * 100 : 0.0;
                    final isAbove = diff > 0.5;
                    final isBelow = diff < -0.5;

                    final bool isFirst = index == 0;

                    return GestureDetector(
                      onTap: () => _showBuyConfirmation(offer),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFirst ? Colors.green : Colors.grey.shade300,
                            width: isFirst ? 2 : 1,
                          ),
                          color: isFirst ? Colors.green.shade50 : Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Badge "Melhor oferta" para o primeiro
                                if (isFirst) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Melhor oferta',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                ] else
                                  const Spacer(),

                                // Variação vs mercado
                                if (isAbove || isBelow)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAbove ? Colors.orange.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${isAbove ? '+' : ''}${diff.toStringAsFixed(1)}% ${isAbove ? 'acima' : 'abaixo'} do mercado',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isAbove ? Colors.orange.shade700 : Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatMoney(pricePerToken),
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                      Text(
                                        'por token',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$qty tokens disponíveis',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Total: ${_formatMoney(totalCents / 100)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(sellerName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Comprar',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuyConfirmation(Map<String, dynamic> offer) async {
    final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
    final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
    final totalCostCents = priceCents * qty;

    // Verifica saldo antes de mostrar dialog de confirmação
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final rawBalance = inner['balanceCents'];
      final balanceCents = rawBalance is int ? rawBalance : (rawBalance is num ? rawBalance.toInt() : 0);
      if (balanceCents < totalCostCents) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saldo insuficiente. Consulte sua carteira.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    } catch (_) {}

    final pricePerToken = priceCents / 100;
    final offerId = offer['id'] as String? ?? '';

    // Controle de quantidade (fixa — compra o anúncio todo)
    int buyQty = qty;
    final senhaController = TextEditingController();
    bool senhaVisivel = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final totalValue = buyQty * pricePerToken;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Confirmar compra', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Resumo da oferta
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Preço por token: ${_formatMoney(pricePerToken)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            Text(
                              'Disponível: $qty tokens',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quantidade (fixa — compra o anúncio todo)
                      const Text('Quantidade', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: Text('$qty tokens', style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 12),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            _formatMoney(totalValue),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text('Digite sua senha para confirmar', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 10),
                      if (erro != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: (loading || buyQty <= 0) ? null : () async {
                            if (senhaController.text.isEmpty) {
                              setDialogState(() => erro = 'Informe sua senha');
                              return;
                            }
                            setDialogState(() { loading = true; erro = null; });
                            try {
                              final user = FirebaseAuth.instance.currentUser!;
                              await user.reauthenticateWithCredential(
                                EmailAuthProvider.credential(email: user.email!, password: senhaController.text),
                              );
                              final callable = FirebaseFunctions.instance.httpsCallable('acceptOffer');
                              await callable.call({
                                'offerId': offerId,
                                'quantity': buyQty,
                              });
                              Navigator.pop(dialogContext);
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Compra realizada! $buyQty tokens de ${widget.startupName}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message ?? 'Erro na compra'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            } catch (_) {
                              setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                            }
                          },
                          child: loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Confirmar compra', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
        content: const Text('Você não possui saldo suficiente para esta compra. Adicione saldo na sua carteira.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
