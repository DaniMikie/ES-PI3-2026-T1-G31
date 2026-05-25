/**
 * Autor: Felipe Nasser Coelho Moussa | RA: 25004922
 */

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'market_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/home.svg',
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              width: 24, height: 24,
            ),
            activeIcon: SvgPicture.asset('assets/icons/home.svg',
              colorFilter: const ColorFilter.mode(Color(0xFF2E7D32), BlendMode.srcIn),
              width: 24, height: 24,
            ),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/chart.svg',
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              width: 24, height: 24,
            ),
            activeIcon: SvgPicture.asset('assets/icons/chart.svg',
              colorFilter: const ColorFilter.mode(Color(0xFF2E7D32), BlendMode.srcIn),
              width: 24, height: 24,
            ),
            label: 'Balcão',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/wallet.svg',
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              width: 24, height: 24,
            ),
            activeIcon: SvgPicture.asset('assets/icons/wallet.svg',
              colorFilter: const ColorFilter.mode(Color(0xFF2E7D32), BlendMode.srcIn),
              width: 24, height: 24,
            ),
            label: 'Carteira',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/person.svg',
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              width: 24, height: 24,
            ),
            activeIcon: SvgPicture.asset('assets/icons/person.svg',
              colorFilter: const ColorFilter.mode(Color(0xFF2E7D32), BlendMode.srcIn),
              width: 24, height: 24,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}