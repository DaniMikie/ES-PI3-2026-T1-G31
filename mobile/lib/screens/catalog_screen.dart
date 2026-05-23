// REMOVER DEPOIS

/**
 * Tela de Catálogo de Startups — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 * Alterações: Rafaela Jacobsen | RA: 25004280
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';
import 'login_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _functions = FirebaseFunctions.instance;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _startups = [];
  bool _loading = true;
  String? _selectedStage;
  String? _error;

  final List<Map<String, String>> _stages = [
    {'value': '', 'label': 'Todos'},
    {'value': 'nova', 'label': 'Nova'},
    {'value': 'em_operacao', 'label': 'Em operação'},
    {'value': 'em_expansao', 'label': 'Em expansão'},
  ];

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
        'stage': _selectedStage ?? '',
        'search': _searchController.text.trim(),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final startups = List<Map<String, dynamic>>.from(
        (data['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );
      if (mounted) {
        setState(() {
          _startups = startups;
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

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

  Color _stageColor(String stage) {
    switch (stage) {
      case 'nova':
        return Colors.blue;
      case 'em_operacao':
        return const Color(0xFF2E7D32);
      case 'em_expansao':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'MesclaInvest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Busca e filtro
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Campo de busca
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar startup...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadStartups();
                      },
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                    ),
                  ),
                  onFieldSubmitted: (_) => _loadStartups(),
                ),

                const SizedBox(height: 12),

                // Filtro por estágio
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _stages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final stage = _stages[index];
                      final isSelected = (_selectedStage ?? '') == stage['value'];
                      return FilterChip(
                        label: Text(stage['label']!),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF2E7D32),
                        onSelected: (_) {
                          setState(() {
                            _selectedStage = stage['value']!.isEmpty ? null : stage['value'];
                          });
                          _loadStartups();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de startups
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
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
                    : _startups.isEmpty
                        ? const Center(child: Text('Nenhuma startup encontrada'))
                        : RefreshIndicator(
                            onRefresh: _loadStartups,
                            color: const Color(0xFF2E7D32),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _startups.length,
                              itemBuilder: (context, index) {
                                final startup = _startups[index];
                                final stage = startup['stage'] as String? ?? '';
                                final tags = List<String>.from(startup['tags'] ?? []);
                                final priceCents = startup['currentTokenPriceCents'] as int? ?? 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StartupDetailsScreen(
                                            startupId: startup['id'] as String,
                                            startupName: startup['name'] as String,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Nome e estágio
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  startup['name'] as String? ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _stageColor(stage).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _stageLabel(stage),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _stageColor(stage),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          // Descrição curta
                                          Text(
                                            startup['shortDescription'] as String? ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 12),

                                          // Preço do token
                                          Text(
                                            'Token: R\$ ${(priceCents / 100).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Tags
                                          Wrap(
                                            spacing: 6,
                                            children: tags.map((tag) => Chip(
                                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            )).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
