/**
 * Tela Início — MesclaInvest
 * Autor: Rafaela Jacobsen Braga | RA: 25004280
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'startup_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ── Tela Início ─────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _functions = FirebaseFunctions.instance;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _startups = [];
  List<Map<String, dynamic>> _startupsFiltradas = [];
  bool _loading = true;
  String? _error;

  String _filtroSelecionado = 'Todas';
  final List<String> _filtros = ['Todas', 'Novas', 'Em operação', 'Em expansão'];

  // Mapeia label do filtro para o valor do backend
  String? _filtroParaStage(String filtro) {
    switch (filtro) {
      case 'Novas':
        return 'nova';
      case 'Em operação':
        return 'em_operacao';
      case 'Em expansão':
        return 'em_expansao';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStartups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStartups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final callable = _functions.httpsCallable('listStartups');
      final result = await callable.call({
        'stage': _filtroParaStage(_filtroSelecionado) ?? '',
        'search': _searchController.text.trim(),
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final startups = List<Map<String, dynamic>>.from(
        (data['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      if (mounted) {
        setState(() {
          _startups = startups;
          _startupsFiltradas = startups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar startups';
          _loading = false;
        });
      }
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
      ],
    );
  }

  void _onFiltroTap(String filtro) {
    setState(() => _filtroSelecionado = filtro);
    _loadStartups();
  }

  void _onSearchChanged(String _) => _loadStartups();

  void _verDetalhes(Map<String, dynamic> startup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartupDetailsScreen(
          startupId: startup['id'] as String,
          startupName: startup['name'] as String,
        ),
      ),
    );
  }

  Color _corEstadio(String stage) {
    switch (stage) {
      case 'nova':
        return const Color(0xFF2E7D32);
      case 'em_operacao':
        return const Color(0xFF1565C0);
      case 'em_expansao':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  String _labelEstadio(String stage) {
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

  String _formatarCapital(int cents) {
    final valor = cents / 100;
    if (valor >= 1000) {
      final milhar = valor / 1000;
      return '${milhar % 1 == 0 ? milhar.toInt() : milhar.toStringAsFixed(1)} mil';
    }
    return valor.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', width: 180),
                  ),
                  Positioned(
                    right: 0,
                    child: _buildUserIdentity(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Subtítulo e título Destaques ───────────────────
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Destaques',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Clique na startup para saber mais',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // ── Campo de busca ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextFormField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar startups',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Filtros por estágio ────────────────────────────
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filtros.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filtro = _filtros[index];
                  final selecionado = _filtroSelecionado == filtro;
                  return GestureDetector(
                    onTap: () => _onFiltroTap(filtro),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selecionado ? Colors.black : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        filtro,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selecionado ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Lista de startups ──────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
                  : _error != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStartups,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
                  : _startupsFiltradas.isEmpty
                  ? const Center(
                child: Text(
                  'Nenhuma startup encontrada.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadStartups,
                color: const Color(0xFF2E7D32),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: _startupsFiltradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final startup = _startupsFiltradas[index];
                    final stage = startup['stage'] as String? ?? '';
                    return _StartupCardHome(
                      startup: startup,
                      corEstadio: _corEstadio(stage),
                      labelEstadio: _labelEstadio(stage),
                      formatarCapital: _formatarCapital,
                      onTap: () => _verDetalhes(startup),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card de startup ──────────────────────────────────────────────

class _StartupCardHome extends StatelessWidget {
  final Map<String, dynamic> startup;
  final Color corEstadio;
  final String labelEstadio;
  final String Function(int) formatarCapital;
  final VoidCallback onTap;

  const _StartupCardHome({
    required this.startup,
    required this.corEstadio,
    required this.labelEstadio,
    required this.formatarCapital,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = startup['name'] as String? ?? '';
    final tags = List<String>.from(startup['tags'] ?? []);
    final capitalCents = startup['capitalRaisedCents'] is num ? (startup['capitalRaisedCents'] as num).toInt() : 0;
    final totalTokens = startup['totalTokensIssued'] is num ? (startup['totalTokensIssued'] as num).toInt() : 0;
    final priceCents = startup['currentTokenPriceCents'] is num ? (startup['currentTokenPriceCents'] as num).toInt() : 0;
    // Usa a primeira tag como categoria e shortDescription como descrição
    final categoria = tags.isNotEmpty ? tags.first : '';
    final descricao = startup['shortDescription'] as String? ?? '';
    // Iniciais do nome para o avatar
    final logoInicial = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Linha superior: avatar + info + badge ──────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    logoInicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Nome e categoria
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (categoria.isNotEmpty)
                        Text(
                          categoria,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),

                // Badge do estágio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: corEstadio,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labelEstadio,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Descrição curta
            Text(
              descricao,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Divider(color: Colors.grey.shade200, height: 1),

            const SizedBox(height: 12),

            // ── Linha de dados financeiros ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoColuna(
                  valor: 'R\$ ${formatarCapital(capitalCents)}',
                  label: 'Captado',
                ),
                _InfoColuna(
                  valor: '$totalTokens',
                  label: 'Tokens',
                ),
                _InfoColuna(
                  valor: 'R\$ ${(priceCents / 100).toStringAsFixed(2)}',
                  label: 'Por token',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar de coluna de informação ──────────────────────

class _InfoColuna extends StatelessWidget {
  final String valor;
  final String label;

  const _InfoColuna({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}