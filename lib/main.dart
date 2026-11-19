import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens/commerce_screens.dart';
import 'screens/home_screen.dart';
import 'screens/lab_screen.dart';
import 'screens/list_screens.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shop_screen.dart';

void main() => runApp(const ItsClearApp());

class ItsClearApp extends StatefulWidget {
  const ItsClearApp({super.key});

  @override
  State<ItsClearApp> createState() => _ItsClearAppState();
}

class _ItsClearAppState extends State<ItsClearApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _state,
      child: MaterialApp(
        title: 'itsclear™',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) {
          final width = MediaQuery.of(context).size.width;
          if (width <= 520) return child!;
          return Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22346A), Color(0xFF070C20)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: SizedBox(
                width: 390,
                height: 844,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(390, 844),
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        },
        home: AnimatedBuilder(
          animation: _state,
          builder: (_, __) => const PhoneShell(),
        ),
      ),
    );
  }
}

class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key});

  static const _titles = <String>[
    'Delivering to',
    'Shop the harvest',
    'Zero-Maida Lab',
    'Your basket',
    'My account',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final subtitles = <String>[
      'Lucknow, Uttar Pradesh',
      '${state.filteredProducts.length} stoneground flours',
      'Batch #IC-0426',
      '${state.cartCount} items',
      'Verified member',
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.cream),
          child: Column(
            children: [
              AppTopBar(
                title: _titles[state.tab],
                subtitle: subtitles[state.tab],
                showLogo: state.tab == 0,
                actions: _actions(context, state),
              ),
              Expanded(
                child: IndexedStack(
                  index: state.tab,
                  children: const [
                    HomeScreen(),
                    ShopScreen(),
                    LabScreen(),
                    CartScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
              BottomDock(
                selectedIndex: state.tab,
                cartCount: state.cartCount,
                onTap: state.goTab,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, AppState state) {
    if (state.tab == 0) {
      return [
        RoundIconButton(
          icon: Icons.favorite_border,
          onTap: () => pushScreen(context, const WishlistScreen()),
        ),
        const SizedBox(width: 6),
        RoundIconButton(
          icon: Icons.notifications_none,
          onTap: () => pushScreen(context, const NotificationsScreen()),
        ),
      ];
    }
    if (state.tab == 1) {
      return [
        RoundIconButton(
          icon: Icons.search,
          onTap: () => pushScreen(context, const SearchScreen()),
        ),
        const SizedBox(width: 6),
        RoundIconButton(
          icon: Icons.favorite_border,
          onTap: () => pushScreen(context, const WishlistScreen()),
        ),
      ];
    }
    if (state.tab == 2) {
      return [
        RoundIconButton(
          icon: Icons.download,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate is part of this UI demo'),
              duration: Duration(milliseconds: 900),
            ),
          ),
        ),
      ];
    }
    if (state.tab == 3) {
      return [
        RoundIconButton(
          icon: Icons.add,
          onTap: () => state.goTab(1),
        ),
      ];
    }
    return [
      RoundIconButton(
        icon: Icons.notifications_none,
        onTap: () => pushScreen(context, const NotificationsScreen()),
      ),
    ];
  }
}
