/**
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendRecEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-mail de recuperação enviado!')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao enviar e-mail';
        if (e.code == 'user-not-found') {
          message = 'E-mail não cadastrado';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    }
  }

  void _returnToLoginScreen() {
    Navigator.pop(context); // Voltar para a tela de login
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

                  // Logo (texto por enquanto)
                  Center(child: Image.asset('assets/images/logo.png', width: 200)),

                  const SizedBox(height: 32),

                  // Título
                  const Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Campo e-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Digite seu email',
                      hintText: 'seuemail@exemplo.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // Botão enviar
                  ElevatedButton(
                    onPressed: _sendRecEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text(
                      'Enviar email de verificação',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Voltar para login
                  Center(
                    child: GestureDetector(
                      onTap: _returnToLoginScreen,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Color(0xFF2E7D32),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Voltar para página de login',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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