/*
---------- Tela de Configuração de TOTP (2FA) ----------
- Autora Principal: Daniela Mikie Kikuchi Gonçalves | RA: 25003068

Fluxo de ativação do 2FA (autenticação de dois fatores):
1. Ao abrir a tela, chama Cloud Function "enableTotp" que gera um segredo TOTP
2. O segredo é retornado como URL otpauth:// (padrão do Google Authenticator)
3. Exibe QR Code com essa URL pra o usuário escanear no app autenticador
4. Também mostra o segredo em texto (pra quem não consegue escanear)
5. Usuário digita o código de 6 dígitos gerado pelo app autenticador
6. Cloud Function "verifyTotp" valida o código com action "activate"
7. Se válido, 2FA fica ativo — próximos logins vão pedir o código

Tecnologias:
- qr_flutter: gera o QR Code a partir da URL otpauth://
- Cloud Functions: enableTotp (gera segredo) e verifyTotp (valida código)
*/

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  final _functions = FirebaseFunctions.instance;
  final _codeController = TextEditingController();

  String? _otpauthUrl;
  String? _secret;
  bool _loading = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Gera o segredo TOTP no backend e recebe a URL pro QR Code
  // A Cloud Function "enableTotp" cria um segredo único pro usuário
  // e retorna a URL no formato otpauth://totp/... que o Google Authenticator entende
  Future<void> _generateSecret() async {
    try {
      final callable = _functions.httpsCallable('enableTotp');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);

      if (mounted) {
        setState(() {
          _otpauthUrl = inner['otpauthUrl'] as String?;
          _secret = inner['secret'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao gerar codigo. Tente novamente.';
          _loading = false;
        });
      }
    }
  }

  // Verifica o código de 6 dígitos digitado pelo usuário
  // Envia pra Cloud Function "verifyTotp" com action "activate"
  // Se o código bater com o segredo gerado, ativa o 2FA permanentemente
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Digite o codigo de 6 digitos');
      return;
    }

    setState(() { _verifying = true; _error = null; });

    try {
      final callable = _functions.httpsCallable('verifyTotp');
      await callable.call({'code': code, 'action': 'activate'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticacao multifator ativada!'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() { _error = e.message ?? 'Codigo invalido'; _verifying = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao verificar. Tente novamente.'; _verifying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Ativar 2FA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Autenticacao Multifator',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Escaneie o QR code abaixo com o Google Authenticator ou outro app de autenticacao.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // QR Code
                  if (_otpauthUrl != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: _otpauthUrl!,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Secret manual (caso não consiga escanear)
                  if (_secret != null) ...[
                    const Text('Ou digite manualmente:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      _secret!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Campo de código
                  const Text(
                    'Digite o codigo de 6 digitos do app:',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                    ),

                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _verifying
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Verificar e ativar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
