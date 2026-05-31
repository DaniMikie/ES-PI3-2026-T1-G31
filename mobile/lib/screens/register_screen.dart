/*
---------- Tela de Criar Conta ----------
- Autora Principal: Daniela Mikie Kikuchi Gonçalves | RA: 25003068

Fluxo de cadastro:
1. Usuário preenche: nome, e-mail, CPF, telefone, senha e confirmação
2. Validações locais: CPF válido (algoritmo de dígitos verificadores),
   telefone com 11 dígitos, senhas iguais, e-mail no formato correto
3. Firebase Auth cria a conta (createUserWithEmailAndPassword)
4. Envia e-mail de verificação (necessário pra ativar 2FA depois)
5. Cloud Function "createUser" salva dados extras no Firestore (CPF, telefone)
6. Se CPF ou telefone já existem no banco, mostra erro específico

Máscaras de input:
- CPF: ###.###.###-## (MaskTextInputFormatter)
- Telefone: (##) #####-#### (MaskTextInputFormatter)
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _functions = FirebaseFunctions.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _viewPassword = false;
  bool _viewConfirmPassword = false;
  String? _formError;
  String? _cpfError;
  String? _phoneError;
  String? _emailError;

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validação de CPF usando algoritmo oficial dos dígitos verificadores
  // O CPF tem 11 dígitos: 9 dígitos base + 2 dígitos verificadores
  // Cada dígito verificador é calculado com uma soma ponderada dos anteriores
  // Se os dígitos calculados batem com os informados, o CPF é válido
  bool _isValidCpf(String cpf) {
    if (cpf.length != 11) return false;
    // Rejeita CPFs com todos os dígitos iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    // Calcula primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int d1 = 11 - (sum % 11);
    if (d1 >= 10) d1 = 0;
    if (int.parse(cpf[9]) != d1) return false;

    // Calcula segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int d2 = 11 - (sum % 11);
    if (d2 >= 10) d2 = 0;
    if (int.parse(cpf[10]) != d2) return false;

    return true;
  }

  // Função principal de cadastro
  // 1. Limpa erros anteriores
  // 2. Valida formulário (campos obrigatórios, CPF, senhas iguais)
  // 3. Cria conta no Firebase Auth
  // 4. Envia e-mail de verificação
  // 5. Salva dados extras (CPF, telefone) via Cloud Function
  // 6. Trata erros específicos (e-mail duplicado, CPF duplicado, etc.)
  void _register() async {
    setState(() { _formError = null; _cpfError = null; _phoneError = null; _emailError = null; });
    if (_formKey.currentState!.validate()) {
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await credential.user?.updateDisplayName(_nameController.text.trim());

        // Envia email de verificação (necessário pra ativar MFA depois)
        await credential.user?.sendEmailVerification();

        // Salva dados extras no Firestore
        final callable = _functions.httpsCallable('createUser');
        await callable.call({
          'name': _nameController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta criada! Verifique seu email para ativar todas as funcionalidades.')),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          if (e.code == 'email-already-in-use') {
            setState(() => _emailError = 'Este e-mail já está cadastrado');
          } else if (e.code == 'weak-password') {
            setState(() => _formError = 'A senha deve ter pelo menos 6 caracteres');
          } else if (e.code == 'invalid-email') {
            setState(() => _emailError = 'E-mail inválido');
          } else {
            setState(() => _formError = 'Erro ao criar conta');
          }
          _formKey.currentState!.validate();
        }
      } catch (e) {
        // Se a Cloud Function falhou, o usuário já foi criado no Authentication
        // mas não no Firestore. Precisa deletar do Auth pra não ficar inconsistente.
        // Sem isso, o e-mail fica "ocupado" no Auth mas sem dados no Firestore.
        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } catch (_) {
          // Se não conseguir deletar (ex: token expirado), ignora
        }
        if (mounted) {
          String errorMsg = 'Erro ao salvar dados do usuário';
          if (e is FirebaseFunctionsException) {
            errorMsg = e.message ?? errorMsg;
            if (errorMsg.toLowerCase().contains('cpf')) {
              setState(() => _cpfError = 'Este CPF já está cadastrado');
            } else if (errorMsg.toLowerCase().contains('telefone') || errorMsg.toLowerCase().contains('phone')) {
              setState(() => _phoneError = 'Este telefone já está cadastrado');
            } else {
              setState(() => _formError = errorMsg);
            }
          } else {
            setState(() => _formError = errorMsg);
          }
          _formKey.currentState!.validate();
        }
      }
    }
  }

  void _returnToLogin() {
    Navigator.pop(context);
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
                  Center(child: Image.asset('assets/images/logo.png', width: 200)),
                  const SizedBox(height: 24),
                  const Text(
                    'Criar conta',
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
                  if (_formError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade500),
                      ),
                      child: Text(_formError!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Campo Nome
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome completo*',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'assets/icons/person.svg',
                            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                            width: 24,
                            height: 24,
                          ),
                        ),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu nome completo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email*',
                      hintText: 'seuemail@exemplo.com',
                      hintStyle: const TextStyle(
                        color: Color(0xFFC8C8C8),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/email.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu e-mail';
                      if (!value.contains('@')) return 'E-mail inválido';
                      if (_emailError != null) return _emailError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campo CPF
                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cpfMask],
                    decoration: InputDecoration(
                      labelText: 'CPF*',
                      hintText: '000.000.000-00',
                      hintStyle: const TextStyle(
                        color: Color(0xFFC8C8C8),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/pencil.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu CPF';
                      if (_cpfMask.getUnmaskedText().length != 11) return 'CPF incompleto';
                      if (!_isValidCpf(_cpfMask.getUnmaskedText())) return 'CPF inválido';
                      if (_cpfError != null) return _cpfError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campo Telefone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMask],
                    decoration: InputDecoration(
                      labelText: 'Telefone celular*',
                      hintText: '(00) 00000-0000',
                      hintStyle: const TextStyle(
                        color: Color(0xFFC8C8C8),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/phone.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu telefone';
                      if (_phoneMask.getUnmaskedText().length != 11) return 'Telefone incompleto';
                      if (_phoneError != null) return _phoneError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campo Senha
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_viewPassword,
                    decoration: InputDecoration(
                      labelText: 'Senha*',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/password.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: SvgPicture.asset(
                          _viewPassword
                              ? 'assets/icons/eye_on.svg'
                              : 'assets/icons/eye_off.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () =>
                            setState(() => _viewPassword = !_viewPassword),
                      ),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe sua senha';
                      if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campo Confirmar Senha
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_viewConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha*',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/password.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: SvgPicture.asset(
                          _viewConfirmPassword
                              ? 'assets/icons/eye_on.svg'
                              : 'assets/icons/eye_off.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () => setState(() => _viewConfirmPassword = !_viewConfirmPassword),
                      ),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Confirme sua senha';
                      if (value != _passwordController.text) return 'As senhas não coincidem';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botão Cadastrar
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: const Text('Cadastrar', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),

                  // Voltar para login
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Já tem conta? ', style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: _returnToLogin,
                          child: const Text(
                            'Fazer login',
                            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
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
