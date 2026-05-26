/**
 * Tela Meus Anúncios — MesclaInvest
 * Autor: Daniela Mikie Kikuchi Gonçalves | RA: 25003068
 */

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final _functions = FirebaseFunctions.instance;
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _loading = true);
    try {
      final callable = _functions.httpsCallable('listMyOffers');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final inner = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final offers = List<Map<String, dynamic>>.from(
        (inner['offers'] as List?)?.map((o) => Map<String, dynamic>.from(o as Map)) ?? [],
      );
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelOffer(String offerId) async {
    try {
      final callable = _functions.httpsCallable('cancelOffer');
      await callable.call({'offerId': offerId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anuncio cancelado. Tokens devolvidos.'), backgroundColor: Color(0xFF2E7D32)));
        _loadOffers();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Erro ao cancelar'), backgroundColor: Colors.red));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.orange;
      case 'sold': return const Color(0xFF2E7D32);
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Ativo';
      case 'sold': return 'Vendido';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Meus anuncios', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _offers.isEmpty
              ? const Center(child: Text('Nenhum anuncio criado', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadOffers,
                  color: const Color(0xFF2E7D32),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      final status = offer['status'] as String? ?? '';
                      final startupName = offer['startupName'] as String? ?? '';
                      final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
                      final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
                      final priceReais = priceCents / 100;
                      final totalReais = qty * priceReais;
                      final offerId = offer['id'] as String? ?? '';
                      final buyerUid = offer['buyerUid'] as String?;
                      final logo = startupName.length >= 2 ? startupName.substring(0, 2).toUpperCase() : 'S';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(10)),
                                  alignment: Alignment.center,
                                  child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('$qty tokens a R\$ ${priceReais.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                  child: Text(_statusLabel(status), style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total: R\$ ${totalReais.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (status == 'sold' && buyerUid != null)
                                  const Text('Comprado', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                              ],
                            ),
                            if (status == 'active') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _confirmCancel(offerId),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Cancelar anuncio'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _confirmCancel(String offerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar anuncio?'),
        content: const Text('Os tokens serao devolvidos para sua carteira.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nao')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _cancelOffer(offerId); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar anuncio', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
