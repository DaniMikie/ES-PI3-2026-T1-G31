/**
 * Tela Confirmação de Investimento (com modal de autenticação) — MesclaInvest
 * Autor: [Nome do Autor] | RA: [RA do Autor]
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _modalAberto = true;

  void _fecharModal() {
    setState(() => _modalAberto = false);
  }

  void _abrirModal() {
    setState(() => _modalAberto = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Conteúdo de fundo (desfocado quando modal aberto) ──
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
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão Avançar desabilitado (cinza) quando modal aberto
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: ElevatedButton(
                    onPressed: _modalAberto ? null : _abrirModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
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

            // ── Overlay escuro quando modal aberto ────────────────
            if (_modalAberto)
              GestureDetector(
                onTap: _fecharModal,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),

            // ── Modal de autenticação ──────────────────────────────
            if (_modalAberto)
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.of(context).size.height * 0.28,
                child: _ModalAutenticacao(
                  onConfirmar: (senha) {
                    _fecharModal();
                    // TO-DO: VALIDAR SENHA E CONFIRMAR COMPRA NO BACKEND
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Compra confirmada: ${widget.quantidadeTokens} tokens em ${widget.startupNome}',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Modal de autenticação ────────────────────────────────────────

class _ModalAutenticacao extends StatefulWidget {
  final void Function(String senha) onConfirmar;

  const _ModalAutenticacao({required this.onConfirmar});

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
              // Título do modal
              const Text(
                'Autenticação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              const Text(
                'Digite sua senha para realizar a compra',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Campo de senha
              TextFormField(
                controller: _senhaController,
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
                    onPressed: () =>
                        setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide:
                    BorderSide(color: Color(0xFF2E7D32), width: 2),
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

              // Botão Confirmar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
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