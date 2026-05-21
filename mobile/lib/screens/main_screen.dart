/**
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'market_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indexAtual = 0;

  // Telas em ordem
  final List<Widget> _telas = const [
    HomeScreen(),
    MarketScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  Widget _buildBody() {
    // Wallet e Profile sempre recriam pra pegar dados atualizados
    switch (_indexAtual) {
      case 2:
        return const WalletScreen();
      case 3:
        return const ProfileScreen();
      default:
        return IndexedStack(
          index: _indexAtual,
          children: _telas,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexAtual,
        onTap: (index) => setState(() => _indexAtual = index),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Balcão',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Carteira',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}