import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _functions = FirebaseFunctions.instance;

  bool _mfaAtivo = true;

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

  // 🔹 LOAD PROFILE
  Future<void> _loadUserProfile() async {
    try {
      final callable = _functions.httpsCallable('getUserProfile');

      final result = await callable.call();

      final data = Map<String, dynamic>.from(result.data as Map);
      final user = Map<String, dynamic>.from(data['data']);

      if (!mounted) return;

      setState(() {
        _dadosUsuario = {
          'nomeCompleto': user['nomeCompleto'] ?? '',
          'email': user['email'] ?? '',
          'cpf': user['cpf'] ?? '',
          'telefone': user['telefone'] ?? '',
        };

        _mfaAtivo = user['mfaAtivo'] ?? false;
      });
    } catch (e) {
      print('Erro ao carregar perfil: $e');
    }
  }

  void _alterarDado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegar para edição de dados')),
    );
  }

  // 🔹 UPDATE MFA
  Future<void> _onMfaToggle(bool valor) async {
    setState(() => _mfaAtivo = valor);

    try {
      final callable = _functions.httpsCallable('updateMfaPreference');

      await callable.call({
        'mfaAtivo': valor,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Autenticação Multifator ${valor ? 'ativada' : 'desativada'}',
          ),
        ),
      );
    } catch (e) {
      // rollback se der erro
      setState(() => _mfaAtivo = !valor);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar MFA'),
        ),
      );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, size: 22),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'MesclaInvest',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Seus dados',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _CampoInfo(
                      label: 'Nome Completo*',
                      valor: _dadosUsuario['nomeCompleto']!,
                    ),

                    const SizedBox(height: 20),

                    _CampoInfo(
                      label: 'Email*',
                      valor: _dadosUsuario['email']!,
                    ),

                    const SizedBox(height: 20),

                    _CampoInfo(
                      label: 'CPF*',
                      valor: _dadosUsuario['cpf']!,
                    ),

                    const SizedBox(height: 20),

                    _CampoInfo(
                      label: 'Telefone*',
                      valor: _dadosUsuario['telefone']!,
                    ),

                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Senha*',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: Colors.grey.shade300,
                          height: 1,
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    ElevatedButton(
                      onPressed: _alterarDado,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Alterar dado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    Row(
                      children: [
                        Switch(
                          value: _mfaAtivo,
                          onChanged: _onMfaToggle,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF2E7D32),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ativar Autenticação Multifator',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          color: Colors.grey.shade300,
          height: 1,
        ),
      ],
    );
  }
}