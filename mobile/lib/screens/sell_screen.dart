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

  const SellScreen({super.key, required this.startupId, required this.startupName, required this.tokenPrice, required this.totalTokens, required this.stage, required this.tags});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
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
            const Text('Anunciar tokens', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
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
            const Text('Quantia de tokens a ser anunciada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Digite a quantidade de tokens a ser vendida', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                onPressed: quantity > 0 ? _efetuarVenda : null,
                child: const Text('Efetuar anuncio', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _efetuarVenda() async {
    // Verifica tokens antes
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final positions = List<Map<String, dynamic>>.from((innerData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? []);
      final pos = positions.where((p) => p['startupId'] == widget.startupId).toList();
      final userQty = pos.isNotEmpty ? (pos.first['quantity'] as int? ?? 0) : 0;
      if (userQty < quantity) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voce possui apenas $userQty tokens'), backgroundColor: Colors.red));
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
                  const Text('Digite sua senha para realizar a venda', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                          final callable = FirebaseFunctions.instance.httpsCallable('sellTokens');
                          await callable.call({'startupId': widget.startupId, 'quantity': quantity});
                          Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Venda realizada! $quantity tokens'), backgroundColor: Colors.green));
                            Navigator.pop(context);
                          }
                        } on FirebaseAuthException catch (_) {
                          setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                        } on FirebaseFunctionsException catch (e) {
                          Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Tokens insuficientes'), backgroundColor: Colors.red));
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
}
