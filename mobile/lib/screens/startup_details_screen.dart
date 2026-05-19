/**
 * Tela de Detalhes da Startup — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'investment_screen.dart';

class StartupDetailsScreen extends StatefulWidget {
  final String startupId;
  final String startupName;

  const StartupDetailsScreen({
    super.key,
    required this.startupId,
    required this.startupName,
  });

  @override
  State<StartupDetailsScreen> createState() => _StartupDetailsScreenState();
}

class _StartupDetailsScreenState extends State<StartupDetailsScreen> {
  final _functions = FirebaseFunctions.instance;
  Map<String, dynamic>? _startup;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final callable = _functions.httpsCallable('getStartupDetails');
      final result = await callable.call({'id': widget.startupId});
      final data = Map<String, dynamic>.from(result.data as Map);
      if (mounted) {
        setState(() {
          _startup = Map<String, dynamic>.from(data['data'] as Map);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar detalhes';
          _loading = false;
        });
      }
    }
  }

  void _sellTokens() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Vender tokens'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Quantidade de tokens'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(controller.text);
                if (qty == null || qty <= 0) return;
                Navigator.pop(context);
                try {
                  final callable = _functions.httpsCallable('sellTokens');
                  await callable.call({'startupId': widget.startupId, 'quantity': qty});
                  _loadDetails();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$qty tokens vendidos!'), backgroundColor: const Color(0xFF2E7D32)),
                    );
                  }
                } on FirebaseFunctionsException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Erro ao vender'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Vender', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _sendPrivateQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Pergunta privada'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Digite sua pergunta...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                Navigator.pop(context);
                try {
                  final callable = _functions.httpsCallable('createStartupQuestion');
                  await callable.call({
                    'startupId': widget.startupId,
                    'text': controller.text.trim(),
                    'visibility': 'privada',
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pergunta enviada!'), backgroundColor: Color(0xFF2E7D32)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao enviar pergunta'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Enviar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'nova':
        return 'Nova';
      case 'em_operacao':
        return 'Em operação';
      case 'em_expansao':
        return 'Em expansão';
      default:
        return stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.startupName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetails,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e estágio
                      Text(
                        _startup!['name'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _stageLabel(_startup!['stage'] as String? ?? ''),
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sumário executivo
                      const Text(
                        'Sumário Executivo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _startup!['executiveSummary'] as String? ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 24),

                      // Descrição
                      const Text(
                        'Descrição',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _startup!['description'] as String? ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 24),

                      // Dados financeiros
                      const Text(
                        'Dados Financeiros',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Capital levantado',
                          'R\$ ${((_startup!['capitalRaisedCents'] as int? ?? 0) / 100).toStringAsFixed(2)}'),
                      _buildInfoRow('Tokens emitidos',
                          '${_startup!['totalTokensIssued'] ?? 0}'),
                      _buildInfoRow('Preço do token',
                          'R\$ ${((_startup!['currentTokenPriceCents'] as int? ?? 0) / 100).toStringAsFixed(2)}'),

                      const SizedBox(height: 24),

                      // Sócios
                      const Text(
                        'Sócios',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...(_startup!['founders'] as List? ?? []).map((founder) {
                        final f = Map<String, dynamic>.from(founder as Map);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF2E7D32),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(f['name'] as String? ?? ''),
                            subtitle: Text('${f['role'] ?? ''} — ${f['equityPercent'] ?? 0}%'),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Membros externos
                      if ((_startup!['externalMembers'] as List? ?? []).isNotEmpty) ...[
                        const Text(
                          'Membros Externos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...(_startup!['externalMembers'] as List).map((member) {
                          final m = Map<String, dynamic>.from(member as Map);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.group, color: Colors.white),
                              ),
                              title: Text(m['name'] as String? ?? ''),
                              subtitle: Text('${m['role'] ?? ''} — ${m['organization'] ?? ''}'),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Perguntas públicas
                      if ((_startup!['publicQuestions'] as List? ?? []).isNotEmpty) ...[
                        const Text(
                          'Perguntas Públicas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...(_startup!['publicQuestions'] as List).map((question) {
                          final q = Map<String, dynamic>.from(question as Map);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q['text'] as String? ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (q['answer'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Resposta: ${q['answer']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2E7D32),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Tags
                      Wrap(
                        spacing: 6,
                        children: (List<String>.from(_startup!['tags'] ?? [])).map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 11)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Botão Investir (todos os usuários)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final priceCents = _startup!['currentTokenPriceCents'] as int? ?? 0;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvestmentScreen(
                                  startupId: widget.startupId,
                                  startupNome: _startup!['name'] as String? ?? '',
                                  valorPorToken: priceCents / 100,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Investir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      // Botões exclusivos de investidor
                      if (_startup!['access'] != null && _startup!['access']['isInvestor'] == true) ...[
                        const SizedBox(height: 12),

                        // Botão Vender
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _sellTokens,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Vender tokens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botão Pergunta privada
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _sendPrivateQuestion,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Enviar pergunta privada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
