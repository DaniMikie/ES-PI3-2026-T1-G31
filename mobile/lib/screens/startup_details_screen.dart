/*
 * Tela de Detalhes da Startup — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 * Alterações: Rafaela Jacobsen | RA: 25004280
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
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
  int _tabIndex = 0; // 0 = A Startup, 1 = Adquirir tokens

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

  String get _userDisplayName {
    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    return 'Usuário';
  }

  String get _userInitials {
    final parts = _userDisplayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Widget _buildUserIdentity() {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF2E7D32),
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          child: hasPhoto
              ? null
              : Text(
                  _userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _userDisplayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _sellTokens() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Vender tokens'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (erro != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        erro!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Quantidade de tokens',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(controller.text);
                  if (qty == null || qty <= 0) {
                    setDialogState(
                      () => erro = 'Informe uma quantidade válida',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext);
                  try {
                    final callable = _functions.httpsCallable('sellTokens');
                    await callable.call({
                      'startupId': widget.startupId,
                      'quantity': qty,
                    });
                    _loadDetails();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$qty tokens vendidos!'),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  } on FirebaseFunctionsException catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? 'Erro ao vender'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Vender',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendQuestion({required String visibility}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          visibility == 'privada' ? 'Pergunta privada' : 'Fazer uma pergunta',
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Digite aqui sua pergunta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                final callable = _functions.httpsCallable(
                  'createStartupQuestion',
                );
                await callable.call({
                  'startupId': widget.startupId,
                  'text': controller.text.trim(),
                  'visibility': visibility,
                });
                _loadDetails();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Pergunta enviada!'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao enviar pergunta'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<String> _videoLinks() {
    final rawLinks =
        _startup?['demoVideos'] ??
        _startup?['videos'] ??
        _startup?['videoUrls'] ??
        _startup?['links'];

    if (rawLinks is! List) return [];

    return rawLinks
        .whereType<String>()
        .map((link) => link.trim())
        .where((link) => link.isNotEmpty)
        .toList();
  }

  Future<void> _openVideo(String link) async {
    final uri = Uri.tryParse(link);

    if (uri == null || !uri.hasScheme) {
      _showVideoError();
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) {
      _showVideoError();
    }
  }

  void _showVideoError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir o vídeo'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(_error!)),
      );
    }

    final name = _startup!['name'] as String? ?? '';
    final stage = _startup!['stage'] as String? ?? '';
    final tags = List<String>.from(_startup!['tags'] ?? []);
    final logo = name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'S';
    final categoria = tags.isNotEmpty ? tags.first : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Image.asset('assets/images/logo.png', width: 160),
                  const SizedBox(width: 12),
                  Expanded(child: _buildUserIdentity()),
                ],
              ),
              const SizedBox(height: 20),
              // Startup info
              Row(
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (categoria.isNotEmpty)
                          Text(
                            categoria,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _stageLabel(stage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Tabs
              Row(
                children: [
                  _buildTab('A Startup', 0),
                  const SizedBox(width: 12),
                  _buildTab('Os tokens', 1),
                ],
              ),
              const SizedBox(height: 24),
              // Content
              if (_tabIndex == 0) _buildStartupTab(),
              if (_tabIndex == 1) _buildTokensTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStartupTab() {
    final description = _startup!['description'] as String? ?? '';
    final executiveSummary = _startup!['executiveSummary'] as String? ?? '';
    final founders = List<Map<String, dynamic>>.from(
      (_startup!['founders'] as List?)?.map(
            (f) => Map<String, dynamic>.from(f as Map),
          ) ??
          [],
    );
    final questions = List<Map<String, dynamic>>.from(
      (_startup!['publicQuestions'] as List?)?.map(
            (q) => Map<String, dynamic>.from(q as Map),
          ) ??
          [],
    );
    final privateQuestions = List<Map<String, dynamic>>.from(
      (_startup!['privateQuestions'] as List?)?.map(
            (q) => Map<String, dynamic>.from(q as Map),
          ) ??
          [],
    );
    final isInvestor = _startup!['access']?['isInvestor'] == true;
    final videoLinks = _videoLinks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sobre
        const Text(
          'Sobre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 24),

        if (videoLinks.isNotEmpty) ...[
          const Text(
            'Vídeos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          ...videoLinks.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openVideo(entry.value),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: Text('Abrir vídeo ${entry.key + 1}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Estrutura societária
        const Text(
          'Estrutura societária',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        ...founders.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '${f['equityPercent'] ?? 0}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${f['name']} - ${f['role']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Perguntas e respostas
        const Text(
          'Perguntas e respostas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          const Text(
            'Nenhuma pergunta ainda',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...questions.map(
            (q) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q['text'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (q['answer'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      q['answer'] as String,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Botao de pergunta publica (qualquer usuario)
        GestureDetector(
          onTap: () => _sendQuestion(visibility: 'publica'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E7D32)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Fazer uma pergunta publica',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sócios ativos
        const Text(
          'Sócios ativos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: founders
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'I',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f['name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${f['equityPercent']}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Área do investidor
        if (isInvestor) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Área do já investidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quer comprar ou vender seus tokens?',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _tabIndex = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Ir para os tokens'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Perguntas privadas
          const Text(
            'Perguntas e respostas privadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          if (privateQuestions.isEmpty)
            const Text(
              'Nenhuma pergunta privada ainda',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...privateQuestions.map(
              (q) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['text'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (q['answer'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        q['answer'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2E7D32),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Aguardando resposta...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Campo de pergunta privada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fazer uma pergunta privada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _sendQuestion(visibility: 'privada'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Digite aqui sua pergunta',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Sumário executivo
        const SizedBox(height: 24),
        const Text(
          'Sumário executivo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          executiveSummary,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTokensTab() {
    final capitalCents = _startup!['capitalRaisedCents'] as int? ?? 0;
    final totalTokens = _startup!['totalTokensIssued'] as int? ?? 0;
    final priceCents = _startup!['currentTokenPriceCents'] as int? ?? 0;
    final isInvestor = _startup!['access']?['isInvestor'] == true;
    final userTokens = _startup!['access']?['tokenQuantity'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Valorização (placeholder gráfico)
        const Text(
          'Valorização dos tokens',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                final h = [35.0, 45.0, 40.0, 50.0, 42.0, 70.0][i];
                return Container(
                  width: 20,
                  height: h,
                  decoration: BoxDecoration(
                    color: i == 5
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Os tokens
        const Text(
          'Os tokens',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _tokenInfo(
              'R\$ ${(capitalCents / 100).toStringAsFixed(0)}',
              'Captados',
            ),
            _tokenInfo('$totalTokens', 'Total emitidos'),
            _tokenInfo(
              'R\$ ${(priceCents / 100).toStringAsFixed(2)}',
              'Por token',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Área do investidor
        if (isInvestor) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Área do já investidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Você possui',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '$userTokens tokens',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _sellTokens,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Vender tokens'),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Volta pra MainScreen e vai pra aba Carteira (index 2)
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Consulte seu saldo aqui',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Botão comprar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvestmentScreen(
                    startupId: widget.startupId,
                    startupNome: _startup!['name'] as String? ?? '',
                    valorPorToken: priceCents / 100,
                  ),
                ),
              ).then((_) => _loadDetails());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Comprar tokens',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _tokenInfo(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
