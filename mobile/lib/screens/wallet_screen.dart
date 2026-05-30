/*
 * Tela Carteira — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 *
 * Exibe saldo, patrimônio em tokens, gráfico de patrimônio acumulado
 * (com pontos verdes pra compra e vermelhos pra venda), gráfico de variação
 * por startup com resultado total em R$ e lucro/prejuízo individual,
 * lista de investimentos e histórico de transações.
 */

/*
  Alterações: Ana Luísa Maso Mafra | RA: 25007997
*/

/*
 Alterações: Rafaela Jacobsen Braga | RA: 25004280
*/

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _functions = FirebaseFunctions.instance;

  bool _saldoVisivel = true;
  String _periodoSelecionado = 'Mês';
  final List<String> _periodos = ['Dia', 'Semana', 'Mês', '6 meses', 'YTD'];

  double _saldo = 0;
  int _totalStartups = 0;
  int _totalTokens = 0;
  List<Map<String, dynamic>> _investimentos = [];
  List<Map<String, dynamic>> _transacoes = [];
  Map<String, String> _startupNames = {};
  bool _loading = true;
  String? _errorMessage;

  // Estado do gráfico dinâmico
  List<Map<String, dynamic>> _chartPoints = [];
  double _chartVariation = 0;
  bool _chartLoading = false;
  int _transacoesVisiveis = 5;

  // Estado do gráfico de portfólio
  List<Map<String, dynamic>> _portfolioLines = [];
  bool _portfolioLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _loadTokenHistory();
    _loadPortfolioHistory();
  }

  String _periodToBackend(String period) {
    switch (period) {
      case 'Dia': return 'dia';
      case 'Semana': return 'semana';
      case 'Mês': return 'mes';
      case '6 meses': return '6meses';
      case 'YTD': return 'ytd';
      default: return 'mes';
    }
  }

  Future<void> _loadTokenHistory() async {
    setState(() => _chartLoading = true);
    try {
      final callable = _functions.httpsCallable('getTokenHistory');
      final result = await callable.call({
        'period': _periodToBackend(_periodoSelecionado),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final points = List<Map<String, dynamic>>.from(
        (innerData['points'] as List?)?.map(
              (p) => Map<String, dynamic>.from(p as Map),
            ) ?? [],
      );
      final variation = (innerData['variation'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;
      setState(() {
        _chartPoints = points;
        _chartVariation = variation;
        _chartLoading = false;
      });
    } catch (e) {
      debugPrint('Erro getTokenHistory: $e');
      if (!mounted) return;
      setState(() {
        _chartPoints = [];
        _chartVariation = 0;
        _chartLoading = false;
      });
    }
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final walletResult = await _functions.httpsCallable('getWallet').call();
      final walletData = _unwrapData(walletResult.data);

      final positions = List<Map<String, dynamic>>.from(
        (walletData['positions'] as List?)?.map(
              (p) => Map<String, dynamic>.from(p as Map),
            ) ??
            [],
      );

      final transactions = await _loadTransactions();
      final startupNames = await _loadStartupNames();

      if (!mounted) return;

      setState(() {
        _saldo = _toCents(walletData['balanceCents']) / 100;
        _totalStartups = _toInt(walletData['totalStartups']);
        _totalTokens = _toInt(walletData['totalTokens']);
        _investimentos = positions;
        _transacoes = transactions;
        _startupNames = startupNames;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro getWallet: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível carregar sua carteira.';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    try {
      final result = await _functions.httpsCallable('listTransactions').call();
      final data = _unwrapData(result.data);
      return List<Map<String, dynamic>>.from(
        (data['transactions'] as List?)?.map(
              (t) => Map<String, dynamic>.from(t as Map),
            ) ??
            [],
      );
    } catch (e) {
      debugPrint('Erro listTransactions: $e');
      return [];
    }
  }

  Future<Map<String, String>> _loadStartupNames() async {
    try {
      final result = await _functions.httpsCallable('listStartups').call({
        'stage': '',
        'search': '',
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final startups = List<Map<String, dynamic>>.from(
        (data['data'] as List?)?.map(
              (s) => Map<String, dynamic>.from(s as Map),
            ) ??
            [],
      );

      return {
        for (final startup in startups)
          if (startup['id'] != null && startup['name'] != null)
            startup['id'].toString(): startup['name'].toString(),
      };
    } catch (e) {
      debugPrint('Erro listStartups: $e');
      return {};
    }
  }

  Map<String, dynamic> _unwrapData(Object? value) {
    final data = Map<String, dynamic>.from(value as Map);
    return Map<String, dynamic>.from(data['data'] as Map? ?? data);
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toCents(Object? value) => _toInt(value);

  String _formatMoney(num value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    final digits = intPart.startsWith('-') ? intPart.substring(1) : intPart;
    if (intPart.startsWith('-')) buffer.write('-');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'R\$ $buffer,$decPart';
  }

  String _startupLabel(String startupId) {
    if (startupId.isEmpty) return 'Startup';
    return _startupNames[startupId] ?? startupId;
  }

  String _transactionDate(Map<String, dynamic> transaction) {
    final createdAt = transaction['createdAt'];
    DateTime? date;

    if (createdAt is DateTime) {
      date = createdAt;
    } else if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds is int) {
        date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  void _toggleSaldo() => setState(() => _saldoVisivel = !_saldoVisivel);

  double _saldoFontSize() {
    final text = _formatMoney(_saldo);
    final len = text.length;
    if (len <= 12) return 32;
    if (len <= 15) return 28;
    if (len <= 18) return 24;
    if (len <= 21) return 20;
    return 16;
  }

  void _addCredits() {
    final controller = TextEditingController();
    final parentMessenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        bool loading = false;

        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            title: const Text('Adicionar saldo'),
            content: TextField(
              controller: controller,
              enabled: !loading,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                hintText: '100,00',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final raw = controller.text.trim().replaceAll(',', '.');
                        final valor = double.tryParse(raw);

                        if (valor == null || valor <= 0) {
                          setDialogState(() {
                            errorText = 'Informe um valor maior que zero';
                          });
                          return;
                        }

                        setDialogState(() {
                          loading = true;
                          errorText = null;
                        });

                        try {
                          final navigator = Navigator.of(dialogContext);
                          final callable = _functions.httpsCallable(
                            'addCredits',
                          );
                          await callable.call({
                            'amount': (valor * 100).round(),
                          });
                          if (!mounted) return;

                          navigator.pop();
                          await _loadWallet();

                          if (!mounted) return;
                          parentMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_formatMoney(valor)} adicionado!',
                              ),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            loading = false;
                            errorText = 'Erro ao adicionar saldo';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  /// Exibe o dialog de saque com campo de valor e confirmação de senha.
  /// Após autenticar o usuário via reautenticação com senha, chama
  /// a Cloud Function `withdrawCredits` e atualiza o saldo.
  void _withdrawCredits() {
    final valorController = TextEditingController();
    final senhaController = TextEditingController();
    final parentMessenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? valorError;
        String? senhaError;
        bool loading = false;
        bool senhaVisivel = false;

        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            title: const Text('Sacar saldo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Campo: Valor ──────────────────────────────────────────
                TextField(
                  controller: valorController,
                  enabled: !loading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    labelText: 'Valor a sacar',
                    hintText: '100,00',
                    errorText: valorError,
                  ),
                ),
                const SizedBox(height: 16),
                // ── Campo: Senha (para confirmação) ───────────────────────
                TextField(
                  controller: senhaController,
                  enabled: !loading,
                  obscureText: !senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Confirme sua senha',
                    errorText: senhaError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        senhaVisivel
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setDialogState(() => senhaVisivel = !senhaVisivel),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        // 1. Valida o valor informado
                        final raw =
                            valorController.text.trim().replaceAll(',', '.');
                        final valor = double.tryParse(raw);

                        if (valor == null || valor <= 0) {
                          setDialogState(
                            () => valorError = 'Informe um valor maior que zero',
                          );
                          return;
                        }

                        // 2. Valida se a senha foi preenchida
                        final senha = senhaController.text.trim();
                        if (senha.isEmpty) {
                          setDialogState(
                            () => senhaError = 'Informe sua senha',
                          );
                          return;
                        }

                        setDialogState(() {
                          loading = true;
                          valorError = null;
                          senhaError = null;
                        });

                        try {
                          // 3. Reautentica o usuário com email + senha
                          //    (garante que quem está sacando é o dono da conta)
                          final currentUser =
                              FirebaseAuth.instance.currentUser;
                          if (currentUser == null || currentUser.email == null) {
                            throw FirebaseAuthException(
                              code: 'user-not-found',
                              message: 'Usuário não autenticado.',
                            );
                          }

                          final credential = EmailAuthProvider.credential(
                            email: currentUser.email!,
                            password: senha,
                          );
                          await currentUser
                              .reauthenticateWithCredential(credential);

                          // 4. Chama a Cloud Function withdrawCredits
                          final navigator = Navigator.of(dialogContext);
                          final callable =
                              _functions.httpsCallable('withdrawCredits');
                          await callable.call({
                            'amount': (valor * 100).round(),
                          });

                          if (!mounted) return;

                          // 5. Fecha o dialog e recarrega a carteira
                          navigator.pop();
                          await _loadWallet();

                          if (!mounted) return;
                          parentMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Saque de ${_formatMoney(valor)} realizado!',
                              ),
                              backgroundColor: Colors.black87,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          // Senha incorreta ou erro de autenticação
                          setDialogState(() {
                            loading = false;
                            senhaError = e.code == 'wrong-password' ||
                                    e.code == 'invalid-credential'
                                ? 'Senha incorreta'
                                : 'Erro de autenticação';
                          });
                        } on FirebaseFunctionsException catch (e) {
                          // Saldo insuficiente ou outro erro da function
                          setDialogState(() {
                            loading = false;
                            valorError = e.code == 'failed-precondition'
                                ? 'Saldo insuficiente'
                                : 'Erro ao realizar saque';
                          });
                        } catch (e) {
                          setDialogState(() {
                            loading = false;
                            valorError = 'Erro inesperado. Tente novamente.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirmar saque',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      valorController.dispose();
      senhaController.dispose();
    });
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $_userName',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _saldoVisivel
                                        ? _formatMoney(_saldo)
                                        : 'R\$ ••••••',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _saldoFontSize(),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: _toggleSaldo,
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Saldo disponível',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _saldoVisivel
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tokens',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_totalStartups startups',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$_totalTokens tokens',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // ── Botões: Adicionar Saldo + Sacar ──────────────────
                        // Implementado por Ana Luísa Maso Mafra
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addCredits,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  '+ Adicionar Saldo',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _withdrawCredits,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: const BorderSide(
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  '↑ Sacar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: RefreshIndicator(
                        color: const Color(0xFF2E7D32),
                        onRefresh: _loadWallet,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          child: _errorMessage != null
                              ? _buildError()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAnalysis(),
                                    const SizedBox(height: 28),
                                    _buildPortfolioChart(),
                                    const SizedBox(height: 28),
                                    _buildInvestments(),
                                    const SizedBox(height: 28),
                                    _buildTransactions(),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 34),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico de operações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Preço médio dos tokens que você comprou e vendeu ao longo do tempo',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (!_chartLoading && _chartPoints.isNotEmpty && _chartPoints.length > 1)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_chartVariation >= 0 ? '↑' : '↓'} ${_chartVariation.abs().toStringAsFixed(2)}% de variação',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _periodos.map((p) {
                  final sel = _periodoSelecionado == p;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _periodoSelecionado = p);
                      _loadTokenHistory();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.grey,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: _chartLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      )
                    : _chartPoints.isEmpty
                        ? const Center(
                            child: Text(
                              'Realize compras ou vendas para visualizar o gráfico',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _buildDynamicChart(),
              ),
              const SizedBox(height: 8),
              // Legenda
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Compra', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Venda/Saque', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Container(width: 12, height: 3, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  const Text('Patrimônio (R\$)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicChart() {
    final values = _chartPoints
        .map((p) => (p['value'] as num?)?.toDouble() ?? 0)
        .toList();
    final labels = _chartPoints
        .map((p) => p['label'] as String? ?? '')
        .toList();
    final types = _chartPoints
        .map((p) => p['type'] as String? ?? 'buy')
        .toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    String formatAxis(double v) {
      final reais = v / 100;
      if (reais >= 1000000) return 'R\$ ${(reais / 1000000).toStringAsFixed(1)}M';
      if (reais >= 1000) return 'R\$ ${(reais / 1000).toStringAsFixed(1)}k';
      if (reais >= 10) return 'R\$ ${reais.toStringAsFixed(0)}';
      return 'R\$ ${reais.toStringAsFixed(2)}';
    }

    // Arredonda eixo Y pra valores mais legíveis
    double roundedMax = maxValue;
    double roundedMin = minValue;
    final reaisMax = maxValue / 100;
    final reaisMin = minValue / 100;
    if (reaisMax >= 10) {
      roundedMax = (reaisMax.ceil()) * 100;
    }
    if (reaisMin >= 10) {
      roundedMin = (reaisMin.floor()) * 100;
    } else if (reaisMin > 0) {
      roundedMin = ((reaisMin * 10).floor() / 10) * 100;
    }

    List<String> xLabels;
    if (labels.length <= 4) {
      xLabels = labels;
    } else {
      xLabels = [labels.first, labels[labels.length ~/ 2], labels.last];
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatAxis(roundedMax), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  if (roundedMax != roundedMin)
                    Text(formatAxis((roundedMax + roundedMin) / 2), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(formatAxis(roundedMin), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(values: values, types: types, color: const Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: xLabels.map((l) => Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey))).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _loadPortfolioHistory() async {
    setState(() => _portfolioLoading = true);
    try {
      final callable = _functions.httpsCallable('getPortfolioHistory');
      final result = await callable.call({'period': _periodToBackend(_periodoSelecionado)});
      final data = Map<String, dynamic>.from(result.data as Map);
      final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final lines = List<Map<String, dynamic>>.from(
        (inner['lines'] as List?)?.map((l) => Map<String, dynamic>.from(l as Map)) ?? [],
      );
      if (mounted) setState(() { _portfolioLines = lines; _portfolioLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _portfolioLines = []; _portfolioLoading = false; });
    }
  }

  Widget _buildPortfolioChart() {
    if (_portfolioLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
    }
    if (_portfolioLines.isEmpty) return const SizedBox.shrink();

    // Calcula range global pra eixo Y
    double maxVar = 0;
    double minVar = 0;
    List<String> allTimestamps = [];
    for (final line in _portfolioLines) {
      final points = List<Map<String, dynamic>>.from(
        (line['points'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      for (final p in points) {
        final v = (p['variation'] as num?)?.toDouble() ?? 0;
        if (v > maxVar) maxVar = v;
        if (v < minVar) minVar = v;
      }
      if (points.length > allTimestamps.length) {
        allTimestamps = points.map((p) => p['timestamp'] as String? ?? '').toList();
      }
    }
    // Garante margem mínima no eixo Y
    if (maxVar == 0 && minVar == 0) { maxVar = 5; minVar = -5; }
    if (maxVar <= 0) maxVar = 2;
    if (minVar >= 0) minVar = -2;

    // Labels do eixo X (primeiro, meio, último)
    List<String> xLabels;
    if (allTimestamps.length <= 3) {
      xLabels = allTimestamps;
    } else {
      xLabels = [allTimestamps.first, allTimestamps[allTimestamps.length ~/ 2], allTimestamps.last];
    }

    // Calcula lucro/prejuízo em R$ usando _investimentos (fonte confiável)
    // Fórmula: (preço atual - preço médio de compra) × quantidade de tokens
    // Positivo = lucro, Negativo = prejuízo
    double totalProfitCents = 0;
    final profitByStartup = <String, double>{};
    for (final inv in _investimentos) {
      final startupId = inv['startupId'] as String? ?? '';
      final quantity = (inv['quantity'] as num?)?.toDouble() ?? 0;
      final totalInvested = (inv['totalInvestedCents'] as num?)?.toDouble() ?? 0;
      final currentPrice = (inv['currentTokenPriceCents'] as num?)?.toDouble() ?? 0;
      final avgBuy = quantity > 0 ? totalInvested / quantity : 0.0;
      final profit = (currentPrice - avgBuy) * quantity;
      profitByStartup[startupId] = profit;
      totalProfitCents += profit;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Variação por startup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 4),
        const Text('Lucro ou prejuízo de cada investimento ao longo do tempo', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        // Resultado total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: totalProfitCents >= 0 ? const Color(0xFF2E7D32).withAlpha(25) : Colors.red.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                totalProfitCents >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: totalProfitCents >= 0 ? const Color(0xFF2E7D32) : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                'Resultado total: ${totalProfitCents >= 0 ? '+' : '-'}R\$ ${(totalProfitCents.abs() / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: totalProfitCents >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    // Eixo Y (percentuais)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('+${maxVar.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        const Text('0%', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        Text('${minVar.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    // Gráfico
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _MultiLineChartPainter(lines: _portfolioLines),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // === Labels de % ao lado direito do gráfico ===
                    // Cada label fica na mesma altura Y onde a linha termina.
                    // Usa LayoutBuilder pra saber a altura disponível e calcular
                    // a posição exata de cada label com a mesma fórmula do painter.
                    // Se dois labels ficam muito perto, empurra o de baixo pra não sobrepor.
                    SizedBox(
                      width: 42,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final chartHeight = constraints.maxHeight;
                          final range = maxVar - minVar;

                          // Calcula posição Y de cada label baseado na variação final
                          final items = <_PortfolioLabel>[];
                          for (final line in _portfolioLines) {
                            final color = _parseColor(line['color'] as String? ?? '#2E7D32');
                            final points = List<Map<String, dynamic>>.from(
                              (line['points'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
                            );
                            final lastV = points.isNotEmpty ? (points.last['variation'] as num?)?.toDouble() ?? 0 : 0.0;
                            // Usa a mesma fórmula yForValue do painter pra alinhar
                            final chartTop = chartHeight * 0.05;
                            final chartBottom = chartHeight * 0.95;
                            final cH = chartBottom - chartTop;
                            final y = chartBottom - ((lastV - minVar) / range) * cH;
                            items.add(_PortfolioLabel(value: lastV, y: y, color: color));
                          }

                          // Ordena por posição Y (de cima pra baixo)
                          // e garante espaçamento mínimo de 14px entre labels
                          items.sort((a, b) => a.y.compareTo(b.y));
                          const minSpacing = 14.0;
                          for (int i = 1; i < items.length; i++) {
                            if (items[i].y - items[i - 1].y < minSpacing) {
                              items[i] = _PortfolioLabel(
                                value: items[i].value,
                                y: items[i - 1].y + minSpacing,
                                color: items[i].color,
                              );
                            }
                          }

                          return Stack(
                            children: items.map((item) {
                              return Positioned(
                                top: (item.y - 6).clamp(0, chartHeight - 14),
                                left: 0,
                                child: Text(
                                  '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item.color),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Eixo X (timestamps)
              if (xLabels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 36, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: xLabels.map((l) => Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey))).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              // Legenda
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: _portfolioLines.map((line) {
                  final name = line['startupName'] as String? ?? '';
                  final color = _parseColor(line['color'] as String? ?? '#2E7D32');
                  final points = List<Map<String, dynamic>>.from(
                    (line['points'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
                  );
                  final lastVariation = points.isNotEmpty ? (points.last['variation'] as num?)?.toDouble() ?? 0 : 0.0;
                  final startupId = line['startupId'] as String? ?? '';
                  final profitCents = profitByStartup[startupId] ?? 0;
                  final profitStr = '${profitCents >= 0 ? '+' : '-'}R\$ ${(profitCents.abs() / 100).toStringAsFixed(2)}';
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Text('$name ', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                      Text('$profitStr (${lastVariation >= 0 ? '+' : ''}${lastVariation.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lastVariation >= 0 ? const Color(0xFF2E7D32) : Colors.red)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildInvestments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seus investimentos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 16),
        if (_investimentos.isEmpty)
          _buildEmptyState('Nenhum investimento ainda')
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _investimentos.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final inv = _investimentos[index];
                final startupId = inv['startupId'] as String? ?? '';
                final startupName = _startupLabel(startupId);
                final quantity = _toInt(inv['quantity']);
                final totalCents = _toCents(inv['totalInvestedCents']);
                final currentPriceCents = _toInt(inv['currentTokenPriceCents']);
                final logo = startupName.length >= 2
                    ? startupName.substring(0, 2).toUpperCase()
                    : 'ST';

                final avgBuyCents = quantity > 0 ? totalCents / quantity : 0.0;
                final variation = avgBuyCents > 0
                    ? ((currentPriceCents - avgBuyCents) / avgBuyCents) * 100
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          logo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              startupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '$quantity tokens',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatMoney(totalCents / 100),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(1)}% lucro',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: variation >= 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTransactions() {
    final transacoesExibidas = _transacoes.length > _transacoesVisiveis
        ? _transacoes.sublist(0, _transacoesVisiveis)
        : _transacoes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico de transações',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 16),
        if (_transacoes.isEmpty)
          _buildEmptyState('Nenhuma transação ainda')
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transacoesExibidas.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final transaction = transacoesExibidas[index];
                    final type = transaction['type']?.toString() ?? '';
                    final isBuy = type == 'buy';
                    final isCredit = type == 'credit';
                    final isWithdrawal = type == 'withdrawal';
                    final startupId = transaction['startupId']?.toString() ?? '';
                    final startupName =
                        transaction['startupName']?.toString() ??
                        _startupLabel(startupId);
                    final quantity = _toInt(transaction['quantity']);
                    final totalCents = _toCents(transaction['totalCents']);
                    final date = _transactionDate(transaction);
                    final title = isCredit
                        ? 'Crédito adicionado'
                        : isWithdrawal
                        ? 'Saque realizado'
                        : isBuy
                        ? 'Compra de tokens'
                        : 'Venda de tokens';
                    final subtitle = (isCredit || isWithdrawal)
                        ? (date.isEmpty
                              ? 'Saldo da carteira'
                              : 'Saldo da carteira • $date')
                        : '$startupName • $quantity tokens${date.isEmpty ? '' : ' • $date'}';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isWithdrawal
                            ? Colors.black87
                            : isBuy
                            ? const Color(0xFF2E7D32)
                            : Colors.black,
                        child: Icon(
                          isWithdrawal
                              ? Icons.arrow_upward
                              : isCredit
                              ? Icons.add
                              : isBuy
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: Text(
                        '${(isBuy || isWithdrawal) ? '-' : '+'} ${_formatMoney(totalCents / 100)}',
                        style: TextStyle(
                          color: (isBuy || isWithdrawal)
                              ? Colors.red.shade700
                              : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
                if (_transacoes.length > _transacoesVisiveis)
                  GestureDetector(
                    onTap: () => setState(() => _transacoesVisiveis += 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: const Center(
                        child: Text('Ver mais', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

/// Painter do gráfico de patrimônio (linha única).
/// Mostra a evolução do valor total dos tokens do usuário ao longo do tempo.
/// Pontos verdes = compras (patrimônio subiu), pontos vermelhos = vendas (patrimônio desceu).
class _LineChartPainter extends CustomPainter {
  final List<double> values;   // Valores do patrimônio em cada ponto (em centavos)
  final List<String> types;    // Tipo de cada ponto: "buy" ou "sell"
  final Color color;           // Cor base da linha (verde)

  _LineChartPainter({required this.values, this.types = const [], required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;  // Precisa de pelo menos 2 pontos pra desenhar linha

    // Encontra valor máximo e mínimo pra escalar o gráfico
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    // Linhas de grade horizontais tracejadas (referência visual)
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Posições das 3 linhas de grade: topo (5%), meio (47.5%), base (90%)
    final gridPositions = [0.05, 0.475, 0.9];
    for (final pos in gridPositions) {
      final y = size.height * pos;
      final gridPath = Path();
      for (double x = 0; x < size.width; x += 6) {
        gridPath.moveTo(x, y);
        gridPath.lineTo(x + 3, y);
      }
      canvas.drawPath(gridPath, gridPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Preenchimento gradiente abaixo da linha (vai sumindo pra baixo)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(51), color.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      // X: distribui igualmente ao longo da largura
      final x = (i / (values.length - 1)) * size.width;
      // Y: proporção do valor dentro do range (0 = mínimo, 1 = máximo)
      // Se range é 0 (todos valores iguais), coloca no meio (0.5)
      final proportion = range > 0 ? (values[i] - minVal) / range : 0.5;
      // Converte proporção pra posição Y (inverte pq Y cresce pra baixo)
      // Usa 85% da altura com 5% de margem embaixo
      final y = size.height - (proportion * size.height * 0.85) - (size.height * 0.05);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fecha e preenche a área abaixo da linha
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Desenha a linha por cima
    canvas.drawPath(path, linePaint);

    // Desenha ponto em cada transação
    // Verde = compra (patrimônio subiu), Vermelho = venda (patrimônio desceu)
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final type = i < types.length ? types[i] : 'buy';
      final pointColor = type == 'sell' ? Colors.red : color;
      final pointPaint = Paint()..color = pointColor..style = PaintingStyle.fill;
      // Borda branca + ponto colorido (efeito de destaque)
      canvas.drawCircle(point, 5, dotBorderPaint);
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Helper pra posicionar os labels de % ao lado direito do gráfico.
/// Cada label fica na mesma altura Y onde a linha da startup termina,
/// com espaçamento mínimo pra evitar sobreposição de texto.
class _PortfolioLabel {
  final double value;
  final double y;
  final Color color;
  const _PortfolioLabel({required this.value, required this.y, required this.color});
}

/// Painter do gráfico multi-linha de variação por startup.
/// Cada linha representa uma startup com cor diferente.
/// Desenha: linhas de grade tracejadas (max, 0%, min), gradient fill,
/// pontos nos vértices e destaque no primeiro/último ponto.
class _MultiLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> lines;

  _MultiLineChartPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty) return;

    // === PASSO 1: Encontrar o range global ===
    // Precisa saber o maior e menor valor de variação entre TODAS as startups
    // pra saber como escalar o gráfico (onde fica o topo e onde fica a base)
    double maxVar = 0;
    double minVar = 0;
    for (final line in lines) {
      final points = List<Map<String, dynamic>>.from(
        (line['points'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      for (final p in points) {
        final v = (p['variation'] as num?)?.toDouble() ?? 0;
        if (v > maxVar) maxVar = v;
        if (v < minVar) minVar = v;
      }
    }

    // Se tudo é zero, cria uma margem artificial pra não dividir por zero
    if (maxVar == 0 && minVar == 0) { maxVar = 5; minVar = -5; }
    if (maxVar <= 0) maxVar = 2;
    if (minVar >= 0) minVar = -2;

    final range = maxVar - minVar;
    if (range == 0) return;

    // === PASSO 2: Definir área útil do gráfico ===
    // Deixa 5% de margem em cima e embaixo pra não colar na borda
    final chartTop = size.height * 0.05;
    final chartBottom = size.height * 0.95;
    final chartHeight = chartBottom - chartTop;

    // Converte um valor de variação (%) pra posição Y no canvas
    // Quanto maior o valor, mais pra cima (Y menor, pq Y cresce pra baixo)
    double yForValue(double v) {
      return chartBottom - ((v - minVar) / range) * chartHeight;
    }

    // === PASSO 3: Linhas de grade tracejadas ===
    // Desenha 3 linhas horizontais pontilhadas: no máximo, no 0% e no mínimo
    // Ajuda o usuário a ter referência visual de onde está cada valor
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final gridVal in [maxVar, 0.0, minVar]) {
      final y = yForValue(gridVal);
      // Cria tracejado manualmente (segmentos de 3px com espaço de 3px)
      final gridPath = Path();
      for (double x = 0; x < size.width; x += 6) {
        gridPath.moveTo(x, y);
        gridPath.lineTo(x + 3, y);
      }
      canvas.drawPath(gridPath, gridPaint);
    }

    // === PASSO 4: Desenhar cada linha (uma por startup) ===
    for (final line in lines) {
      final points = List<Map<String, dynamic>>.from(
        (line['points'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      if (points.length < 2) continue;

      // Converte a cor hex (#2E7D32) pra objeto Color do Flutter
      final colorHex = (line['color'] as String? ?? '#2E7D32').replaceAll('#', '');
      final color = Color(int.parse('FF$colorHex', radix: 16));

      // Paint da linha principal
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Paint dos pontos (bolinhas) em cada vértice
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Borda branca ao redor dos pontos (pra destacar do fundo)
      final dotBorderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;

      // Gradient fill: cor semi-transparente que vai sumindo de cima pra baixo
      // Dá efeito visual de "área preenchida" abaixo da linha
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(38), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final path = Path();       // Caminho da linha
      final fillPath = Path();   // Caminho do preenchimento (área abaixo)

      // Percorre cada ponto e calcula posição X,Y no canvas
      for (int i = 0; i < points.length; i++) {
        final v = (points[i]['variation'] as num?)?.toDouble() ?? 0;
        // X: distribui igualmente ao longo da largura
        final x = (i / (points.length - 1)) * size.width;
        // Y: converte o valor de variação pra posição vertical
        final y = yForValue(v);

        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, chartBottom);
          fillPath.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }

        // Ponto em cada vértice
        // Primeiro e último ponto são maiores (4.5px com borda branca)
        // Pontos do meio são menores (2.5px sem borda)
        if (i == 0 || i == points.length - 1) {
          canvas.drawCircle(Offset(x, y), 4.5, dotBorderPaint);
          canvas.drawCircle(Offset(x, y), 3, dotPaint);
        } else {
          canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
        }
      }

      // Fecha o path do fill (desce até a base e volta pro início)
      fillPath.lineTo(size.width, chartBottom);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);

      // Desenha a linha por cima do fill
      canvas.drawPath(path, linePaint);

      // Ponto final destacado (último valor da linha)
      final lastV = (points.last['variation'] as num?)?.toDouble() ?? 0;
      final lastX = size.width;
      final lastY = yForValue(lastV);
      canvas.drawCircle(Offset(lastX, lastY), 4.5, dotBorderPaint);
      canvas.drawCircle(Offset(lastX, lastY), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
