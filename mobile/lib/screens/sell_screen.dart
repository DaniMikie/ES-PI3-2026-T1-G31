// Autora: Ana Luisa Maso Mafra - RA: 25007997
// Integracao: Daniela Mikie Kikuchi Goncalves - RA: 25003068

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';

class SellScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double tokenPrice;
  final int totalTokens;
  final String stage;
  final List<String> tags;

  const SellScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.tokenPrice,
    required this.totalTokens,
    required this.stage,
    required this.tags,
  });

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  int quantity = 0;
  double _customPrice = 0;
  double get totalValue => quantity * _customPrice;
  int _myTokens = 0;
  bool _loadingTokens = true;

  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preenche o preço com o valor atual do token como sugestão
    _customPrice = widget.tokenPrice;
    _priceController.text = widget.tokenPrice.toStringAsFixed(2).replaceAll('.', ',');
    _loadMyTokens();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTokens() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final positions = List<Map<String, dynamic>>.from(
        (innerData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      final pos = positions.where((p) => p['startupId'] == widget.startupId).toList();
      final rawQty = pos.isNotEmpty ? pos.first['quantity'] : 0;
      if (mounted) {
        setState(() {
          _myTokens = rawQty is int ? rawQty : (rawQty is num ? rawQty.toInt() : 0);
          _loadingTokens = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTokens = false);
    }
  }

  String _formatMoney(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final logo = widget.startupName.length >= 2
        ? widget.startupName.substring(0, 2).toUpperCase()
        : 'S';
    final bool canSell = quantity > 0 && _customPrice > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/images/logo.png', width: 150),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Criar anúncio de venda',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Defina a quantidade e o seu preço por token',
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
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tokens disponíveis
            _loadingTokens
                ? const Text('Carregando...', style: TextStyle(color: Colors.grey, fontSize: 13))
                : Text(
                    'Você possui $_myTokens tokens disponíveis',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
            const SizedBox(height: 4),
            Text(
              'Preço de mercado atual: ${_formatMoney(widget.tokenPrice)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StartupDetailsScreen(startupId: widget.startupId, startupName: widget.startupName)),
              ),
              child: const Row(children: [
                Text('Quer saber mais informações? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Ir para a startup', style: TextStyle(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                Icon(Icons.arrow_forward, size: 14, color: const Color(0xFF2E7D32)),
              ]),
            ),
            const SizedBox(height: 28),

            // Quantidade───────────────────────────────────────────────
            const Text('Quantidade de tokens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Quantos tokens deseja anunciar?', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                suffixText: 'Tokens',
                suffixStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              onChanged: (v) => setState(() => quantity = int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 20),

            // Preço por token──────────────────────────────────────────
            const Text('Seu preço por token', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [
              const Text('Preço sugerido (mercado): ', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                _formatMoney(widget.tokenPrice),
                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0,00',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixText: 'R\$ ',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                setState(() => _customPrice = parsed);
              },
            ),

            // Indicador de variação em relação ao preço de mercado
            if (_customPrice > 0 && widget.tokenPrice > 0) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final diff = ((_customPrice - widget.tokenPrice) / widget.tokenPrice) * 100;
                final isAbove = diff > 0;
                final isBelow = diff < 0;
                return Row(children: [
                  Icon(
                    isAbove ? Icons.trending_up : (isBelow ? Icons.trending_down : Icons.trending_flat),
                    size: 16,
                    color: isAbove ? Colors.orange : (isBelow ? Colors.blue : Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAbove
                        ? '${diff.toStringAsFixed(1)}% acima do mercado'
                        : isBelow
                            ? '${diff.abs().toStringAsFixed(1)}% abaixo do mercado'
                            : 'Igual ao preço de mercado',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAbove ? Colors.orange : (isBelow ? Colors.blue : Colors.grey),
                    ),
                  ),
                ]);
              }),
            ],
            const SizedBox(height: 24),

            // Total do anúncio─────────────────────────────────────────
            const Text('Total do anúncio:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E7D32)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _formatMoney(totalValue),
                  style: const TextStyle(fontSize: 28, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info sobre como funciona
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: const Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seu anúncio ficará visível para compradores no balcão. Os tokens só são transferidos quando alguém aceitar sua oferta.',
                      style: TextStyle(fontSize: 12, color: const Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: canSell ? _criarAnuncio : null,
                child: const Text('Publicar anúncio', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _criarAnuncio() async {
    if (_myTokens < quantity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você possui apenas $_myTokens tokens disponíveis'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (_customPrice <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um preço válido por token'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    _showAuthDialog();
  }

  void _showAuthDialog() {
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
                  const Text('Confirmar anúncio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Resumo do anúncio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$quantity tokens × ${_formatMoney(_customPrice)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('Total: ${_formatMoney(totalValue)}', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const Text('Digite sua senha para publicar', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
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
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(senhaVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: loading ? null : () async {
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
                          final callable = FirebaseFunctions.instance.httpsCallable('createOffer');
                          await callable.call({
                            'startupId': widget.startupId,
                            'quantity': quantity,
                            // Envia em centavos para o backend (padrão do projeto)
                            'priceCents': (_customPrice * 100).round(),
                          });
                          Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Anúncio publicado! $quantity tokens por ${_formatMoney(_customPrice)} cada'),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } on FirebaseAuthException catch (_) {
                          setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                        } on FirebaseFunctionsException catch (e) {
                          setDialogState(() { erro = e.message ?? 'Erro ao publicar anúncio'; loading = false; });
                        } catch (_) {
                          setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                        }
                      },
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Publicar', style: TextStyle(color: Colors.white, fontSize: 16)),
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
}
