/*
 * Tela de Detalhes da Startup — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 * Alterações: Rafaela Jacobsen | RA: 25004280
 * Ajustes: Felipe Nasser Coelho Moussa | RA: 25004922
 *
 * Gráfico de valorização com cor dinâmica (verde/vermelho/cinza)
 * conforme variação no período — Daniela Mikie | RA: 25003068
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
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
      ),
    );
  }

  void _sellTokens() {
    final qtyController = TextEditingController();
    final senhaController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? erro;
        bool loading = false;
        bool pedindoSenha = false;
        int qty = 0;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(pedindoSenha ? 'Confirmar venda' : 'Vender tokens'),
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
                  if (!pedindoSenha)
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Quantidade de tokens',
                      ),
                    )
                  else ...[
                    Text(
                      'Vender $qty tokens',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: senhaController,
                      obscureText: true,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        hintText: 'Sua senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
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
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!pedindoSenha) {
                          final parsed = int.tryParse(qtyController.text);
                          if (parsed == null || parsed <= 0) {
                            setDialogState(
                              () => erro = 'Informe uma quantidade válida',
                            );
                            return;
                          }
                          // Verifica se tem tokens suficientes
                          final userTokens = _startup!['access']?['tokenQuantity'];
                          final available = userTokens is int ? userTokens : (userTokens is num ? userTokens.toInt() : 0);
                          if (parsed > available) {
                            setDialogState(() => erro = 'Voce possui apenas $available tokens');
                            return;
                          }
                          qty = parsed;
                          setDialogState(() {
                            pedindoSenha = true;
                            erro = null;
                          });
                          return;
                        }
                        if (senhaController.text.isEmpty) {
                          setDialogState(() => erro = 'Informe sua senha');
                          return;
                        }
                        setDialogState(() {
                          loading = true;
                          erro = null;
                        });
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          await user.reauthenticateWithCredential(
                            EmailAuthProvider.credential(
                              email: user.email!,
                              password: senhaController.text,
                            ),
                          );
                          final callable = _functions.httpsCallable(
                            'sellTokens',
                          );
                          await callable.call({
                            'startupId': widget.startupId,
                            'quantity': qty,
                          });
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _loadDetails();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$qty tokens vendidos!'),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        } on FirebaseAuthException catch (_) {
                          setDialogState(() {
                            erro = 'Senha incorreta';
                            loading = false;
                          });
                        } on FirebaseFunctionsException catch (e) {
                          setDialogState(() {
                            erro = e.message ?? 'Erro ao vender';
                            loading = false;
                          });
                        } catch (_) {
                          setDialogState(() {
                            erro = 'Erro inesperado';
                            loading = false;
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
                    : Text(
                        pedindoSenha ? 'Confirmar' : 'Avançar',
                        style: const TextStyle(color: Colors.white),
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
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Digite aqui sua pergunta',
            ),
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

  String? _extractYoutubeId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  List<String> _videoLinks() {
    final rawLinks = _startup?['demoVideos'];

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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('A Startup', 0),
                    const SizedBox(width: 12),
                    _buildTab('Os tokens', 1),
                    const SizedBox(width: 12),
                    _buildTab('Perguntas', 2),
                    const SizedBox(width: 12),
                    _buildTab('Novidades', 3),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Content
              if (_tabIndex == 0) _buildStartupTab(),
              if (_tabIndex == 1) _buildTokensTab(),
              if (_tabIndex == 2) _buildQuestionsTab(),
              if (_tabIndex == 3) _buildUpdatesTab(),
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
    final pitchDeckUrl = _startup!['pitchDeckUrl'] as String? ?? '';
    final founders = List<Map<String, dynamic>>.from(
      (_startup!['founders'] as List?)?.map(
            (f) => Map<String, dynamic>.from(f as Map),
          ) ??
          [],
    );
    final externalMembers = List<Map<String, dynamic>>.from(
      (_startup!['externalMembers'] as List?)?.map(
            (m) => Map<String, dynamic>.from(m as Map),
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
            'Vídeos demonstrativos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          ...videoLinks.asMap().entries.map(
            (entry) {
              final videoId = _extractYoutubeId(entry.value);
              if (videoId != null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _YoutubeVideoPlayer(videoId: videoId),
                );
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openVideo(entry.value),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: Text('Abrir vídeo ${entry.key + 1}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              );
            },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (f['bio'] != null && (f['bio'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    f['bio'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Mentores e conselheiros
        if (externalMembers.isNotEmpty) ...[
          const Text(
            'Mentores e conselheiros',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          ...externalMembers.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name'] as String? ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${m['role'] ?? ''}${m['organization'] != null ? ' • ${m['organization']}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

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

        // Plano de negócios / Pitch Deck
        if (pitchDeckUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Plano de negócios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openVideo(pitchDeckUrl),
              icon: const Icon(Icons.description_outlined, size: 20),
              label: const Text('Abrir plano de negócios'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTokensTab() {
    final capitalCents = _startup!['capitalRaisedCents'] is num
        ? (_startup!['capitalRaisedCents'] as num).toInt()
        : 0;
    final totalTokens = _startup!['totalTokensIssued'] is num
        ? (_startup!['totalTokensIssued'] as num).toInt()
        : 0;
    final priceCents = _startup!['currentTokenPriceCents'] is num
        ? (_startup!['currentTokenPriceCents'] as num).toInt()
        : 0;
    final tokensAvailable = _startup!['tokensAvailable'] is num
        ? (_startup!['tokensAvailable'] as num).toInt()
        : totalTokens;
    final isInvestor = _startup!['access']?['isInvestor'] == true;
    final rawUserTokens = _startup!['access']?['tokenQuantity'];
    final userTokens = rawUserTokens is int
        ? rawUserTokens
        : (rawUserTokens is num ? rawUserTokens.toInt() : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Valorização dinâmica
        const Text(
          'Valorização dos tokens',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        _StartupChart(startupId: widget.startupId),
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
              'R\$ ${_formatNumber((capitalCents / 100).round())}',
              'Captados',
            ),
            _tokenInfo('${_formatNumber(tokensAvailable)}', 'Disponíveis'),
            _tokenInfo(
              'R\$ ${(priceCents / 100).toStringAsFixed(2)}',
              'Por token',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Total emitidos: ${_formatNumber(totalTokens)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    tokensDisponiveis: tokensAvailable,
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

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
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

  Widget _buildQuestionsTab() {
    final questions = List<Map<String, dynamic>>.from(
      (_startup!['publicQuestions'] as List?)?.map(
            (q) => Map<String, dynamic>.from(q as Map),
          ) ?? [],
    );
    final privateQuestions = List<Map<String, dynamic>>.from(
      (_startup!['privateQuestions'] as List?)?.map(
            (q) => Map<String, dynamic>.from(q as Map),
          ) ?? [],
    );
    final isInvestor = _startup!['access']?['isInvestor'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Perguntas públicas
        const Text('Perguntas publicas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          const Text('Nenhuma pergunta ainda', style: TextStyle(color: Colors.grey))
        else
          ...questions.map(
            (q) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q['text'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  if (q['answer'] != null) ...[
                    const SizedBox(height: 8),
                    Text(q['answer'] as String, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Botão pergunta pública
        GestureDetector(
          onTap: () => _sendQuestion(visibility: 'publica'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E7D32)), borderRadius: BorderRadius.circular(12)),
            child: const Text('Fazer uma pergunta publica', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ),

        // Perguntas privadas (só investidores)
        if (isInvestor) ...[
          const SizedBox(height: 32),
          const Text('Perguntas privadas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          const SizedBox(height: 4),
          const Text('Visíveis apenas para voce e a startup', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          if (privateQuestions.isEmpty)
            const Text('Nenhuma pergunta privada ainda', style: TextStyle(color: Colors.grey))
          else
            ...privateQuestions.map(
              (q) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['text'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    if (q['answer'] != null) ...[
                      const SizedBox(height: 8),
                      Text(q['answer'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontStyle: FontStyle.italic)),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('Aguardando resposta...', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _sendQuestion(visibility: 'privada'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(16)),
              child: const Text('Fazer uma pergunta privada', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUpdatesTab() {
    return _UpdatesList(startupId: widget.startupId);
  }
}

// Widget de atualizações e eventos
class _UpdatesList extends StatefulWidget {
  final String startupId;
  const _UpdatesList({required this.startupId});

  @override
  State<_UpdatesList> createState() => _UpdatesListState();
}

class _UpdatesListState extends State<_UpdatesList> {
  final _functions = FirebaseFunctions.instance;
  List<Map<String, dynamic>> _updates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final callable = _functions.httpsCallable('getStartupUpdates');
      final result = await callable.call({'startupId': widget.startupId});
      final data = Map<String, dynamic>.from(result.data as Map);
      final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final updates = List<Map<String, dynamic>>.from(
        (inner['updates'] as List?)?.map((u) => Map<String, dynamic>.from(u as Map)) ?? [],
      );
      if (mounted) setState(() { _updates = updates; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
    }
    if (_updates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Nenhuma atualizacao ainda', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Atualizações e eventos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 16),
        ..._updates.map((u) {
          final isEvent = u['type'] == 'event';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: isEvent ? const Color(0xFF2E7D32) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: isEvent ? const Color(0xFF2E7D32).withOpacity(0.05) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isEvent ? Icons.event : Icons.campaign_outlined, size: 18, color: isEvent ? const Color(0xFF2E7D32) : Colors.grey),
                    const SizedBox(width: 8),
                    Text(isEvent ? 'Evento' : 'Atualização', style: TextStyle(fontSize: 11, color: isEvent ? const Color(0xFF2E7D32) : Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(u['title'] as String? ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(u['content'] as String? ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}

// Widget de gráfico dinâmico da startup
class _StartupChart extends StatefulWidget {
  final String startupId;
  const _StartupChart({required this.startupId});

  @override
  State<_StartupChart> createState() => _StartupChartState();
}

class _StartupChartState extends State<_StartupChart> {
  final _functions = FirebaseFunctions.instance;
  List<Map<String, dynamic>> _points = [];
  double _variation = 0;
  bool _loading = true;
  String _period = 'mes';

  final _periods = ['dia', 'semana', 'mes', '6meses', 'ytd'];
  final _periodLabels = {
    'dia': 'Dia',
    'semana': 'Sem',
    'mes': 'Mês',
    '6meses': '6M',
    'ytd': 'YTD',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final callable = _functions.httpsCallable('getStartupTokenHistory');
      final result = await callable.call({
        'startupId': widget.startupId,
        'period': _period,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final points = List<Map<String, dynamic>>.from(
        (inner['points'] as List?)?.map(
              (p) => Map<String, dynamic>.from(p as Map),
            ) ??
            [],
      );
      final variation = (inner['variation'] as num?)?.toDouble() ?? 0;
      if (mounted) {
        setState(() {
          _points = points;
          _variation = variation;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _points = [];
          _variation = 0;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Seletor de período + variação
          Row(
            children: [
              ..._periods.map((p) {
                final sel = _period == p;
                return GestureDetector(
                  onTap: () {
                    setState(() => _period = p);
                    _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _periodLabels[p] ?? p,
                      style: TextStyle(
                        fontSize: 11,
                        color: sel ? Colors.white : Colors.grey,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              if (!_loading && _points.isNotEmpty)
                Text(
                  '${_variation > 0 ? '+' : ''}${_variation.toStringAsFixed(1)}% no período',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _variation > 0
                        ? const Color(0xFF2E7D32)
                        : _variation < 0
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Gráfico
          SizedBox(
            height: 80,
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                : _points.isEmpty
                ? const Center(
                    child: Text(
                      'Sem dados',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : _buildBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildBars() {
    final values = _points
        .map((p) => (p['value'] as num?)?.toDouble() ?? 0)
        .toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final chartColor = _variation > 0
        ? const Color(0xFF2E7D32)
        : _variation < 0
            ? Colors.red
            : Colors.grey;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('R\$ ${(minVal / 100).toStringAsFixed(2)}', style: TextStyle(fontSize: 9, color: chartColor)),
            Text('R\$ ${(maxVal / 100).toStringAsFixed(2)}', style: TextStyle(fontSize: 9, color: chartColor)),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _StartupLineChartPainter(values: values, color: chartColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_points.isNotEmpty)
              Text(_points.first['label'] as String? ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
            if (_points.length > 1)
              Text(_points.last['label'] as String? ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _YoutubeVideoPlayer extends StatefulWidget {
  final String videoId;
  const _YoutubeVideoPlayer({required this.videoId});

  @override
  State<_YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<_YoutubeVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        showLiveFullscreenButton: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: const Color(0xFF2E7D32),
    );
  }
}

class _StartupLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _StartupLineChartPainter({required this.values, required this.color});

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

      if (i == values.length - 1) {
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
