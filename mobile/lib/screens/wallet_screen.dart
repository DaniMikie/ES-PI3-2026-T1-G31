/*
 * Tela Carteira — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
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

  @override
  void initState() {
    super.initState();
    _loadWallet();
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
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
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

  void _addCredits() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
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
                          final messenger = ScaffoldMessenger.of(context);
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
                          messenger.showSnackBar(
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
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
                        SizedBox(
                          width: double.infinity,
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
        const Text(
          'Análise',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
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
                    onTap: () => setState(() => _periodoSelecionado = p),
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
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final h = [40.0, 50.0, 45.0, 55.0, 48.0, 52.0, 80.0][i];
                    final isLast = i == 6;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: h,
                          decoration: BoxDecoration(
                            color: isLast
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
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
                final logo = startupName.length >= 2
                    ? startupName.substring(0, 2).toUpperCase()
                    : 'ST';

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
                      Text(
                        _formatMoney(totalCents / 100),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transacoes.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final transaction = _transacoes[index];
                final type = transaction['type']?.toString() ?? '';
                final isBuy = type == 'buy';
                final isCredit = type == 'credit';
                final startupId = transaction['startupId']?.toString() ?? '';
                final startupName =
                    transaction['startupName']?.toString() ??
                    _startupLabel(startupId);
                final quantity = _toInt(transaction['quantity']);
                final totalCents = _toCents(transaction['totalCents']);
                final date = _transactionDate(transaction);
                final title = isCredit
                    ? 'Crédito adicionado'
                    : isBuy
                    ? 'Compra de tokens'
                    : 'Venda de tokens';
                final subtitle = isCredit
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
                    backgroundColor: isBuy
                        ? const Color(0xFF2E7D32)
                        : Colors.black,
                    child: Icon(
                      isCredit
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
                    '${isBuy ? '-' : '+'} ${_formatMoney(totalCents / 100)}',
                    style: TextStyle(
                      color: isBuy ? Colors.black : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
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
