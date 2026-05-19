/**
 * Tela Aplicar Investimento — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvestmentScreen extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final double valorPorToken;

  const InvestmentScreen({
    super.key,
    required this.startupId,
    required this.startupNome,
    required this.valorPorToken,
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

  void _onValorChanged(String value) {
    final raw = value.replaceAll(',', '.');
    final valorInvestido = double.tryParse(raw) ?? 0.0;
    setState(() {
      _quantidadeTokens = widget.valorPorToken > 0 ? (valorInvestido / widget.valorPorToken).floor() : 0;
    });
  }

  void _avancar() {
    if (_formKey.currentState!.validate()) {
      if (_quantidadeTokens <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor insuficiente para comprar tokens'), backgroundColor: Colors.red),
        );
        return;
      }
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
                      child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextField(
                    controller: senhaController,
                    obscureText: true,
                    enabled: !loading,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline),
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
                    if (mounted) _showSaldoInsuficiente(e.message ?? 'Erro na compra');
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
      builder: (context) => AlertDialog(
        title: const Text('Você não possui saldo suficiente', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quer saber quanto possui?', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Clique para consultar sua carteira →', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, side: const BorderSide(color: Colors.grey)),
            child: const Text('Voltar para startup'),
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
                          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 22)),
                          const SizedBox(width: 8),
                          Text(widget.startupNome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text('Aplicar investimento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      const SizedBox(height: 24),
                      const Text('Quanto gostaria de investir?', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _valorController,
                        onChanged: _onValorChanged,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: InputDecoration(
                          prefixText: 'R\$  ',
                          hintText: '0,00',
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Informe o valor';
                          final raw = value.replaceAll(',', '.');
                          final parsed = double.tryParse(raw);
                          if (parsed == null || parsed <= 0) return 'Valor inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      const Text('Quantidade de tokens obtidos com o valor', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_quantidadeTokens.toString().padLeft(3, '0'), style: const TextStyle(fontSize: 15)),
                            const Text('Tokens', style: TextStyle(fontSize: 15, color: Colors.grey)),
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
