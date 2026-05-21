// Autora: Ana Luísa Maso Mafra - RA: 25007997

import 'package:flutter/material.dart';
import 'buy_screen.dart';
import 'sell_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool isBuyMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Balcão'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Carteira'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'MesclaInvest',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isBuyMode ? 'Comprar tokens' : 'Anunciar tokens',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isBuyMode
                    ? 'Escolha um modo para negociar seus tokens'
                    : 'Escolha um modo para anunciar seus tokens',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isBuyMode = true),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: isBuyMode ? Colors.black : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Tokens disponíveis',
                            style: TextStyle(
                              color: isBuyMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isBuyMode = false),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: !isBuyMode ? Colors.black : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Anunciar seus tokens',
                            style: TextStyle(
                              color: !isBuyMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar startups',
                  suffixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBuyMode
                    ? 'Clique na startup para saber mais informações'
                    : 'Clique na startup para selecioná-la',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    StartupCard(
                      status: 'Nova',
                      statusColor: Colors.green.shade200,
                      tokens: 1000,
                      tokenPrice: 2.50,
                      isBuyMode: isBuyMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isBuyMode
                                ? const BuyScreen()
                                : const SellScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    StartupCard(
                      status: 'Em operação',
                      statusColor: Colors.blue.shade200,
                      tokens: 500,
                      tokenPrice: 200.00,
                      isBuyMode: isBuyMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isBuyMode
                                ? const BuyScreen()
                                : const SellScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    StartupCard(
                      status: 'Em expansão',
                      statusColor: Colors.red.shade200,
                      tokens: 250,
                      tokenPrice: 102.00,
                      isBuyMode: isBuyMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isBuyMode
                                ? const BuyScreen()
                                : const SellScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartupCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  final int tokens;
  final double tokenPrice;
  final bool isBuyMode;
  final VoidCallback onTap;

  const StartupCard({
    super.key,
    required this.status,
    required this.statusColor,
    required this.tokens,
    required this.tokenPrice,
    required this.isBuyMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'S1',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Startup1',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tecnologia · PUC',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBuyMode
                        ? '$tokens Tokens disponíveis para compra'
                        : '$tokens Tokens',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Valor atual do token: ',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        'R\$ ${tokenPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
