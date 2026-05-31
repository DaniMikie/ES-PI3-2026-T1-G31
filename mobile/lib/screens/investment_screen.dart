/*
---------- Tela de Aplicação de Investimento ----------
- Alterações de Design: Felipe Nasser Coelho Moussa | RA: 25004922
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InvestmentScreen extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final double valorPorToken;
  final int tokensDisponiveis;

  const InvestmentScreen({
    super.key,
    required this.startupId,
    required this.startupNome,
    required this.valorPorToken,
    this.tokensDisponiveis = 999999,
  });

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  int _quantidadeTokens = 0;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  void _onQuantidadeChanged(String value) {
    setState(() {
      _quantidadeTokens = int.tryParse(value) ?? 0;
    });
  }

  double get _valorTotal => _quantidadeTokens * widget.valorPorToken;

  void _avancar() async {
    if (_formKey.currentState!.validate()) {
      if (_quantidadeTokens <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe a quantidade de tokens'), backgroundColor: Color(0xFFB30B0E)),
        );
        return;
      }
      if (_quantidadeTokens > widget.tokensDisponiveis) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximo disponivel: ${widget.tokensDisponiveis} tokens'), backgroundColor: Color(0xFFB30B0E)),
        );
        return;
      }

      // Verifica saldo antes de pedir senha
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('getWallet');
        final result = await callable.call();
        final data = Map<String, dynamic>.from(result.data as Map);
        final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);
        final rawBalance = inner['balanceCents'];
        final balanceCents = rawBalance is int ? rawBalance : (rawBalance is num ? rawBalance.toInt() : 0);
        final costCents = (_valorTotal * 100).round();
        if (balanceCents < costCents) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saldo insuficiente. Consulte sua carteira.'), backgroundColor: Color(0xFFB30B0E)),
            );
          }
          return;
        }
      } catch (_) {}

      _showAuthDialog();
    }
  }

  void _showAuthDialog() {
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(erro!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                    ),
                  TextField(
                    controller: senhaController,
                    obscureText: true,
                    enabled: !loading,
                    decoration:  InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/password.svg',
                          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      hintText: '••••••••',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (senhaController.text.isEmpty) {
                    setDialogState(() => erro = 'Informe sua senha');
                    return;
                  }
                  setDialogState(() { loading = true; erro = null; });

                  try {
                    // Reautentica
                    final user = FirebaseAuth.instance.currentUser!;
                    final credential = EmailAuthProvider.credential(email: user.email!, password: senhaController.text);
                    await user.reauthenticateWithCredential(credential);

                    // Compra tokens
                    final callable = FirebaseFunctions.instance.httpsCallable('buyTokens');
                    final result = await callable.call({'startupId': widget.startupId, 'quantity': _quantidadeTokens});
                    final data = Map<String, dynamic>.from(result.data as Map);
                    final buyData = Map<String, dynamic>.from(data['data'] as Map? ?? data);

                    Navigator.pop(dialogContext);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Compra realizada! ${buyData['quantity']} tokens'), backgroundColor: const Color(0xFF2E7D32)),
                      );
                      Navigator.pop(context, true);
                    }
                  } on FirebaseAuthException catch (_) {
                    setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                  } on FirebaseFunctionsException catch (e) {
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      if (e.code == 'failed-precondition' || (e.message ?? '').toLowerCase().contains('saldo')) {
                        _showSaldoInsuficiente(e.message ?? 'Saldo insuficiente');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Erro na compra'), backgroundColor: Color(0xFFB30B0E)),
                        );
                        Navigator.pop(context);
                      }
                    }
                  } catch (e) {
                    setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaldoInsuficiente(String message) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Saldo insuficiente', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Voce nao possui saldo suficiente para esta compra.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(dialogCtx);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ir para a carteira', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2E7D32)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(dialogCtx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Center(child: Image.asset('assets/images/logo.png', width: 200)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.adaptive.arrow_back, size: 22)),
                          const SizedBox(width: 8),
                          Text(widget.startupNome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text('Comprar tokens', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      const SizedBox(height: 8),
                      Text('Valor por token: R\$ ${widget.valorPorToken.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 24),
                      const Text('Quantos tokens deseja comprar?', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _valorController,
                        onChanged: _onQuantidadeChanged,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          suffixText: 'Tokens',
                          hintText: '10',
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Informe a quantidade';
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed <= 0) return 'Quantidade inválida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      const Text('Valor total em reais', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ElevatedButton(
                onPressed: _avancar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text('Avançar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
