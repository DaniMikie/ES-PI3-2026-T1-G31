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

  @override
  Widget build(BuildContext context) {
    final logo = widget.startupName.length >= 2 ? widget.startupName.substring(0, 2).toUpperCase() : 'S';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/images/logo.png', width: 150),
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
            const Text('Quantia de tokens desejada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Digite a quantidade de tokens que deseja', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: '010', suffixText: 'Tokens', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
              onChanged: (v) => setState(() => quantity = int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 20),
            const Text('Valor em reais:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(20)),
              child: Center(child: Text('R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: quantity > 0 ? _efetuarCompra : null,
                child: const Text('Efetuar compra', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _efetuarCompra() async {
    // Verifica saldo antes
    try {
      final walletCallable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final walletResult = await walletCallable.call();
      final walletData = Map<String, dynamic>.from(walletResult.data as Map);
      final innerData = Map<String, dynamic>.from(walletData['data'] as Map? ?? walletData);
      final balanceCents = innerData['balanceCents'] as int? ?? 0;
      if (balanceCents < (quantity * widget.tokenPrice * 100).round()) {
        if (mounted) _showInsuficiente();
        return;
      }
    } catch (_) {}

    _showAuthDialog();
  }

  void _showAuthDialog() {
    final senhaController = TextEditingController();
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
                  TextField(controller: senhaController, obscureText: true, enabled: !loading, decoration: InputDecoration(hintText: '--------', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
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
                        } on FirebaseFunctionsException catch (_) {
                          Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) _showInsuficiente();
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => _InsuficienteScreen(onVoltar: () => Navigator.pop(context))));
  }
}

class _InsuficienteScreen extends StatelessWidget {
  final VoidCallback onVoltar;
  const _InsuficienteScreen({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Voce nao possui\nsaldo suficiente', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Clique para consultar sua carteira', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                Icon(Icons.arrow_forward, size: 14, color: Colors.green),
              ]),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () { Navigator.pop(context); onVoltar(); },
                  child: const Text('Voltar para o balcao', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
