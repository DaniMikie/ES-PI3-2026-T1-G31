/*
---------- Tela de Compra de Tokens ----------
- Autora Principal: Ana Luisa Maso Mafra | RA: 25007997
*/

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  String _formatMoney(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

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
        color: const Color(0xFF2E7D32),
        onRefresh: _loadOffers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comprar tokens',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
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
                      decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(widget.tags.isNotEmpty ? widget.tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ver ofertas disponíveis',
                              style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Preço de mercado: ${_formatMoney(widget.tokenPrice)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                        ),
                      ]),
                    ),
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
                  Text('Ir para a startup', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2E7D32)),
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
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
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
                      TextButton(onPressed: _loadOffers, child: const Text('Tentar novamente', style: TextStyle(color: Color(0xFF2E7D32)))),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
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
                            color: isFirst ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                            width: isFirst ? 2 : 1,
                          ),
                          color: isFirst ? const Color(0xFFE8F5E9) : Colors.white,
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
                                      color: const Color(0xFF2E7D32),
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
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
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
                                  SvgPicture.asset(
                                    'assets/icons/person.svg',
                                    colorFilter: ColorFilter.mode(Colors.grey.shade500, BlendMode.srcIn),
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(sellerName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
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

  void _showBuyConfirmation(Map<String, dynamic> offer) {
    final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
    final pricePerToken = priceCents / 100;
    final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
    final offerId = offer['id'] as String? ?? '';

    // Quantidade fixa — compra o anúncio todo
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
                        width: double.infinity,
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
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
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
                          child: Text(erro!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                        ),
                      TextField(
                        controller: senhaController,
                        obscureText: !senhaVisivel,
                        enabled: !loading,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/password.svg',
                              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                              width: 24,
                              height: 24,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: SvgPicture.asset(
                              senhaVisivel
                                  ? 'assets/icons/eye_on.svg'
                                  : 'assets/icons/eye_off.svg',
                              colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                              width: 24,
                              height: 24,
                            ),
                            onPressed: () => setDialogState(() => senhaVisivel = !senhaVisivel),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
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
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Compra realizada! $buyQty tokens de ${widget.startupName}'),
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } on FirebaseAuthException catch (_) {
                              setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                            } on FirebaseFunctionsException catch (e) {
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) {
                                if (e.code == 'failed-precondition' || (e.message ?? '').toLowerCase().contains('saldo')) {
                                  _showInsuficiente();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message ?? 'Erro na compra'), backgroundColor: Color(0xFFB30B0E)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
