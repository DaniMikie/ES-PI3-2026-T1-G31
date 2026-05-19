/**
 * Tela Aplicar Investimento — MesclaInvest
 * Autor: Rafaela Jacobsen Braga | RA: 25004280
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
      _quantidadeTokens = widget.valorPorToken > 0
          ? (valorInvestido / widget.valorPorToken).floor()
          : 0;
    });
  }

  void _avancar() async {
    if (_formKey.currentState!.validate()) {
      try {
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('buyTokens');
        final result = await callable.call({
          'startupId': widget.startupId,
          'quantity': _quantidadeTokens,
        });

        final data = Map<String, dynamic>.from(result.data as Map);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Compra realizada! ${data['quantity']} tokens de ${widget.startupNome}',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
          Navigator.pop(context, true);
        }
      } on FirebaseFunctionsException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Erro ao comprar tokens'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro inesperado ao comprar tokens'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                      const SizedBox(height: 32),

                      // ── Logo ──────────────────────────────────────
                      const Center(
                        child: Text(
                          'MesclaInvest',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Seta + nome da startup ────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, size: 22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.startupNome,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Título da seção ───────────────────────────
                      const Text(
                        'Aplicar investimento',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Campo: valor a investir ───────────────────
                      const Text(
                        'Quanto gostaria de investir?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _valorController,
                        onChanged: _onValorChanged,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          prefixText: 'R\$  ',
                          prefixStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                          hintText: '0,00',
                          hintStyle: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                            BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFF2E7D32), width: 2),
                          ),
                          errorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const UnderlineInputBorder(
                            borderSide:
                            BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o valor a investir';
                          }
                          final raw = value.replaceAll(',', '.');
                          final parsed = double.tryParse(raw);
                          if (parsed == null || parsed <= 0) {
                            return 'Informe um valor válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Campo: tokens calculados (somente leitura) ─
                      const Text(
                        'Quantidade de tokens obtidos com o valor',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _quantidadeTokens.toString().padLeft(3, '0'),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              'Tokens',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Botão Avançar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ElevatedButton(
                onPressed: _avancar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Avançar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}