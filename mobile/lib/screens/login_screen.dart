/**
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _viewPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthMultiFactorException catch (e) {
        // Usuário tem MFA ativo — pedir código SMS
        if (mounted) _handleMfaLogin(e.resolver);
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao fazer login';
        if (e.code == 'user-not-found') {
          message = 'Usuário não encontrado';
        } else if (e.code == 'wrong-password') {
          message = 'Senha incorreta';
        } else if (e.code == 'invalid-email') {
          message = 'E-mail inválido';
        } else if (e.code == 'invalid-credential') {
          message = 'E-mail ou senha incorretos';
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _handleMfaLogin(MultiFactorResolver resolver) {
    final codeController = TextEditingController();
    String? verificationId;

    // Pega o primeiro fator (telefone)
    final hint = resolver.hints.first as PhoneMultiFactorInfo;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        bool codeSent = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Envia SMS automaticamente na primeira vez
            if (!codeSent && !loading && verificationId == null) {
              setDialogState(() => loading = true);
              FirebaseAuth.instance.verifyPhoneNumber(
                multiFactorSession: resolver.session,
                multiFactorInfo: hint,
                verificationCompleted: (_) {},
                verificationFailed: (e) {
                  setDialogState(() { erro = e.message ?? 'Erro ao enviar SMS'; loading = false; });
                },
                codeSent: (vId, _) {
                  verificationId = vId;
                  setDialogState(() { codeSent = true; loading = false; });
                },
                codeAutoRetrievalTimeout: (_) {},
              );
            }

            return AlertDialog(
              title: const Text('Verificacao MFA'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (erro != null)
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    Text(
                      codeSent ? 'Digite o codigo enviado para ${hint.phoneNumber}' : 'Enviando codigo SMS...',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    if (codeSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Codigo SMS', hintText: '123456'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                if (codeSent)
                  ElevatedButton(
                    onPressed: loading ? null : () async {
                      if (codeController.text.trim().isEmpty) { setDialogState(() => erro = 'Informe o codigo'); return; }
                      setDialogState(() { loading = true; erro = null; });
                      try {
                        final credential = PhoneAuthProvider.credential(
                          verificationId: verificationId!,
                          smsCode: codeController.text.trim(),
                        );
                        final assertion = PhoneMultiFactorGenerator.getAssertion(credential);
                        await resolver.resolveSignIn(assertion);
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const MainScreen()),
                            (route) => false,
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() { erro = e.code == 'invalid-verification-code' ? 'Codigo incorreto' : (e.message ?? 'Erro'); loading = false; });
                      } catch (e) {
                        setDialogState(() { erro = 'Erro: $e'; loading = false; });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                    child: loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verificar', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset('assets/images/logo.png', width: 200),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '(*)Preencha os campos obrigatórios',
                    style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email*',
                      hintText: 'seuemail@exemplo.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Informe seu e-mail';
                      if (!value.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_viewPassword,
                    decoration: InputDecoration(
                      labelText: 'Senha*',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _viewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _viewPassword = !_viewPassword),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Informe sua senha';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text('Entrar', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Não tem cadastro? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: _createAccount,
                          child: const Text(
                            'Criar nova conta',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
