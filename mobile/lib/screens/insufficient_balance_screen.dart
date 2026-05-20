/**
 * Tela Saldo Insuficiente — MesclaInvest
 * Autor: Rafaela Jacobsen Braga | RA: 25004280
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class InsufficientBalanceScreen extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final double valorInvestido;
  final int quantidadeTokens;

  const InsufficientBalanceScreen({
    super.key,
    required this.startupId,
    required this.startupNome,
    required this.valorInvestido,
    required this.quantidadeTokens,
  });

  @override
  State<InsufficientBalanceScreen> createState() =>
      _InsufficientBalanceScreenState();
}

class _InsufficientBalanceScreenState
    extends State<InsufficientBalanceScreen> {
  final _functions = FirebaseFunctions.instance;

  bool _loadingCarteira = false;

  Future<void> _consultarCarteira() async {
    setState(() => _loadingCarteira = true);

    try {
      final callable = _functions.httpsCallable('getUserWallet');
      await callable.call();

      if (!mounted) return;
      setState(() => _loadingCarteira = false);

      // TO-DO: NAVEGAÇÃO PARA A TELA DE CARTEIRA
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegar para carteira')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCarteira = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao consultar carteira'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Conteúdo de fundo ──────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),

                        // Logo
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

                        // Seta + nome da startup
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child:
                              const Icon(Icons.arrow_back, size: 22),
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

                        // Título
                        const Text(
                          'Aplicar investimento',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Quanto gostaria de investir?',
                          style:
                          TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão Avançar desabilitado (verde claro) no fundo
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF81C784),
                      disabledForegroundColor: Colors.white,
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

            // ── Overlay escuro semitransparente ───────────────
            Container(color: Colors.black.withOpacity(0.15)),

            // ── Modal de saldo insuficiente ────────────────────
            Positioned(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).size.height * 0.28,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título do modal
                      const Text(
                        'Você não posssui\nsaldo suficiente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtítulo + link carteira
                      const Text(
                        'Quer saber quanto possui?',
                        style:
                        TextStyle(fontSize: 13, color: Colors.grey),
                      ),

                      const SizedBox(height: 4),

                      GestureDetector(
                        onTap:
                        _loadingCarteira ? null : _consultarCarteira,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _loadingCarteira
                                ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2E7D32),
                              ),
                            )
                                : const Text(
                              'Clique para consultar sua carteira',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botão Voltar para startup
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Voltar para startup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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