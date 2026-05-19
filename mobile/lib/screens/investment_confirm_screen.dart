/**
 * Tela Confirmação de Investimento (com modal de autenticação) — MesclaInvest
 * Autor: Rafaela Jacobsen Braga | RA: 25004280
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

class InvestmentConfirmScreen extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final double valorInvestido;
  final int quantidadeTokens;

  const InvestmentConfirmScreen({
    super.key,
    required this.startupId,
    required this.startupNome,
    required this.valorInvestido,
    required this.quantidadeTokens,
  });

  @override
  State<InvestmentConfirmScreen> createState() =>
      _InvestmentConfirmScreenState();
}

class _InvestmentConfirmScreenState extends State<InvestmentConfirmScreen> {
  final _functions = FirebaseFunctions.instance;

  bool _modalAberto = true;
  bool _loadingConfirm = false;

  void _fecharModal() {
    setState(() => _modalAberto = false);
  }

  void _abrirModal() {
    setState(() => _modalAberto = true);
  }

  Future<void> _confirmarInvestimento(String senha) async {
    setState(() => _loadingConfirm = true);

    try {
      final callable = _functions.httpsCallable('investInStartup');

      final result = await callable.call({
        'startupId': widget.startupId,
        'valorInvestido': widget.valorInvestido,
        'quantidadeTokens': widget.quantidadeTokens,
        'senha': senha,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;

      setState(() {
        _loadingConfirm = false;
        _modalAberto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message'] as String? ??
                'Investimento confirmado: ${widget.quantidadeTokens} tokens em ${widget.startupNome}',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() => _loadingConfirm = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Erro ao confirmar investimento.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingConfirm = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro inesperado ao confirmar investimento.'),
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
                          'Confira os dados do seu investimento antes de confirmar.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),

                        const SizedBox(height: 28),

                        _InfoCard(
                          startupNome: widget.startupNome,
                          valorInvestido: widget.valorInvestido,
                          quantidadeTokens: widget.quantidadeTokens,
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: ElevatedButton(
                    onPressed:
                    _modalAberto || _loadingConfirm ? null : _abrirModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
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

            if (_modalAberto)
              GestureDetector(
                onTap: _loadingConfirm ? null : _fecharModal,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),

            if (_modalAberto)
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.of(context).size.height * 0.28,
                child: _ModalAutenticacao(
                  loading: _loadingConfirm,
                  onConfirmar: _confirmarInvestimento,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String startupNome;
  final double valorInvestido;
  final int quantidadeTokens;

  const _InfoCard({
    required this.startupNome,
    required this.valorInvestido,
    required this.quantidadeTokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Startup', startupNome),
          const SizedBox(height: 12),
          _row('Valor investido', 'R\$ ${valorInvestido.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _row('Tokens', quantidadeTokens.toString()),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModalAutenticacao extends StatefulWidget {
  final bool loading;
  final void Function(String senha) onConfirmar;

  const _ModalAutenticacao({
    required this.loading,
    required this.onConfirmar,
  });

  @override
  State<_ModalAutenticacao> createState() => _ModalAutenticacaoState();
}

class _ModalAutenticacaoState extends State<_ModalAutenticacao> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_formKey.currentState!.validate()) {
      widget.onConfirmar(_senhaController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Autenticação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Digite sua senha para realizar a compra',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _senhaController,
                enabled: !widget.loading,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: widget.loading
                        ? null
                        : () => setState(
                          () => _senhaVisivel = !_senhaVisivel,
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe sua senha';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.loading ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: widget.loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Confirmar',
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
    );
  }
}