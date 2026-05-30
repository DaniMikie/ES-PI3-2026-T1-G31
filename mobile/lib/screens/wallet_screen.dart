/*
 * Tela Carteira — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
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

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _loadTokenHistory();
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
        Row(
          children: [
            const Text(
              'Análise',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            if (!_chartLoading && _chartPoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _chartVariation >= 0
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Tooltip(
                  message: 'Variação no período selecionado',
                  child: Text(
                    '${_chartVariation >= 0 ? '+' : ''}${_chartVariation.toStringAsFixed(2)}% no período',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _chartVariation >= 0
                          ? const Color(0xFF2E7D32)
                          : Colors.red,
                  ),
                ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
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
                              'Sem dados para este período',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : _buildDynamicChart(),
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
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        // Min/Max referência
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Min: R\$ ${(minValue / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Max: R\$ ${(maxValue / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        // Gráfico de linhas
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _LineChartPainter(values: values, color: const Color(0xFF2E7D32)),
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_chartPoints.isNotEmpty)
              Text(_chartPoints.first['label'] as String? ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
            if (_chartPoints.length > 1)
              Text(_chartPoints.last['label'] as String? ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
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

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final proportion = range > 0 ? (values[i] - minVal) / range : 0.5;
      final y = size.height - (proportion * size.height * 0.85) - (size.height * 0.05);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Ponto no último valor
      if (i == values.length - 1) {
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
    }

    // Preenche área abaixo da linha
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Desenha a linha
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
