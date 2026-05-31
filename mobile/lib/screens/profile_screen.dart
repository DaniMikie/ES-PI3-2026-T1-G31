/*
---------- Tela de Perfil do Usuário ----------
- Autora Principal: Rafaela Jacobsen Braga | RA: 25004280
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'login_screen.dart';
import 'totp_setup_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _functions = FirebaseFunctions.instance;
  bool _mfaAtivo = false;
  bool _loading = true;

  Map<String, String> _dadosUsuario = {
    'nomeCompleto': '',
    'email': '',
    'cpf': '',
    'telefone': '',
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final callable = _functions.httpsCallable('getUserProfile');
      final result = await callable.call();
      final resultData = Map<String, dynamic>.from(result.data as Map);
      final data = Map<String, dynamic>.from(resultData['data'] as Map? ?? resultData);

      if (!mounted) return;
      setState(() {
        _dadosUsuario = {
          'nomeCompleto': data['nomeCompleto'] as String? ?? '',
          'email': data['email'] as String? ?? '',
          'cpf': data['cpf'] as String? ?? '',
          'telefone': data['telefone'] as String? ?? '',
        };
        _mfaAtivo = data['mfaAtivo'] as bool? ?? false;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _alterarSenha() {
    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        String? erroNovaSenha;
        String? erroConfirmar;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Alterar senha'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (erro != null)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(erro!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                    ),
                  TextField(controller: senhaAtualController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha atual')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: novaSenhaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nova senha',
                      errorText: erroNovaSenha,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isNotEmpty && value.length < 6) {
                          erroNovaSenha = 'Mínimo 6 caracteres';
                        } else if (value.isNotEmpty && value == senhaAtualController.text) {
                          erroNovaSenha = 'Deve ser diferente da atual';
                        } else {
                          erroNovaSenha = null;
                        }
                        // Atualiza erro do confirmar se já tem algo digitado
                        if (confirmarSenhaController.text.isNotEmpty && confirmarSenhaController.text != value) {
                          erroConfirmar = 'As senhas não coincidem';
                        } else {
                          erroConfirmar = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmarSenhaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nova senha',
                      errorText: erroConfirmar,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isNotEmpty && value != novaSenhaController.text) {
                          erroConfirmar = 'As senhas não coincidem';
                        } else {
                          erroConfirmar = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () { Navigator.pop(dialogContext); _enviarEmailRedefinicao(); },
                    child: const Text('Nao lembro minha senha', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  // Validações finais antes de salvar
                  if (senhaAtualController.text.isEmpty) { setDialogState(() => erro = 'Informe a senha atual'); return; }
                  if (novaSenhaController.text.length < 6) { setDialogState(() => erroNovaSenha = 'Mínimo 6 caracteres'); return; }
                  if (novaSenhaController.text == senhaAtualController.text) { setDialogState(() => erroNovaSenha = 'Deve ser diferente da atual'); return; }
                  if (novaSenhaController.text != confirmarSenhaController.text) { setDialogState(() => erroConfirmar = 'As senhas não coincidem'); return; }

                  // Tenta reautenticar — se a senha atual estiver errada, mostra erro no dialog
                  try {
                    final user = FirebaseAuth.instance.currentUser!;
                    await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: senhaAtualController.text));
                    await user.updatePassword(novaSenhaController.text);
                    Navigator.pop(dialogContext);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso!'), backgroundColor: Color(0xFF2E7D32)));
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                      setDialogState(() => erro = 'Senha atual incorreta');
                    } else {
                      setDialogState(() => erro = 'Erro ao alterar senha');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('Salvar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _enviarEmailRedefinicao() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('E-mail enviado para $email'), backgroundColor: const Color(0xFF2E7D32)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar e-mail'), backgroundColor: Color(0xFFB30B0E)));
    }
  }

  void _alterarDados() {
    final nameController = TextEditingController(text: _dadosUsuario['nomeCompleto']);
    final phoneController = TextEditingController(text: _dadosUsuario['telefone']);
    final phoneMask = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar dados'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome completo')),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [phoneMask],
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(00) 00000-0000',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final callable = _functions.httpsCallable('updateUserProfile');
                await callable.call({'name': nameController.text.trim(), 'phone': phoneController.text.trim()});
                if (mounted) {
                  setState(() { _dadosUsuario['nomeCompleto'] = nameController.text.trim(); _dadosUsuario['telefone'] = phoneController.text.trim(); });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados!'), backgroundColor: Color(0xFF2E7D32)));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar'), backgroundColor: Color(0xFFB30B0E)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sairDoPerfil() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _onMfaToggle(bool valor) async {
    if (valor) {
      // Ativar MFA — abrir tela de configuração TOTP
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TotpSetupScreen()),
      );
      if (result == true) {
        setState(() => _mfaAtivo = true);
      }
    } else {
      // Desativar MFA — pedir código pra confirmar
      _showDisableTotpDialog();
    }
  }

  void _showDisableTotpDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Desativar 2FA'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Digite o codigo do Google Authenticator para confirmar', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                if (erro != null)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(erro!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                  ),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(hintText: '000000', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (codeController.text.trim().length != 6) { setDialogState(() => erro = 'Codigo de 6 digitos'); return; }
                  setDialogState(() { loading = true; erro = null; });
                  try {
                    final callable = _functions.httpsCallable('disableTotp');
                    await callable.call({'code': codeController.text.trim()});
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    setState(() => _mfaAtivo = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA desativado'), backgroundColor: Color(0xFF2E7D32)));
                  } on FirebaseFunctionsException catch (e) {
                    setDialogState(() { erro = e.message ?? 'Codigo invalido'; loading = false; });
                  } catch (_) {
                    setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB30B0E)),
                child: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Desativar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text('Seus dados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    const SizedBox(height: 28),
                    _CampoInfo(label: 'Nome Completo*', valor: _dadosUsuario['nomeCompleto']!),
                    const SizedBox(height: 20),
                    _CampoInfo(label: 'Email*', valor: _dadosUsuario['email']!),
                    const SizedBox(height: 20),
                    _CampoInfo(label: 'CPF*', valor: _dadosUsuario['cpf']!),
                    const SizedBox(height: 20),
                    _CampoInfo(label: 'Telefone*', valor: _dadosUsuario['telefone']!),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Senha*', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        const Text('••••••••', style: TextStyle(fontSize: 15, color: Colors.black)),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade300, height: 1),
                        const SizedBox(height: 8),
                        GestureDetector(onTap: _alterarSenha, child: const Text('Alterar senha', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Switch(value: _mfaAtivo, onChanged: _onMfaToggle, activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF2E7D32), inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        const Text('Ativar Autenticação Multifator', style: TextStyle(fontSize: 15, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _alterarDados,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), elevation: 0),
                        child: const Text('Alterar dados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sairDoPerfil,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), elevation: 0),
                        child: const Text('Sair desse perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CampoInfo extends StatelessWidget {
  final String label;
  final String valor;
  const _CampoInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(valor.isNotEmpty ? valor : 'Nao informado', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade300, height: 1),
      ],
    );
  }
}
