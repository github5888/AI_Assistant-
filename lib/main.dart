import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'store_api.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens/commerce_screens.dart';
import 'screens/checkout_flow.dart';
import 'screens/home_screen.dart';
import 'screens/lab_screen.dart';
import 'screens/list_screens.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shop_screen.dart';

void main() {
  const base = String.fromEnvironment('ITSCLEAR_API_BASE_URL', defaultValue: StoreApi.productionUrl);
  runApp(ItsClearApp(api: StoreApi(base)));
}

class ItsClearApp extends StatefulWidget {
  const ItsClearApp({super.key, this.api});

  final StoreApi? api;

  @override
  State<ItsClearApp> createState() => _ItsClearAppState();
}

class _ItsClearAppState extends State<ItsClearApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(api: widget.api);
    _state.refreshStore();
  }

  @override
  void dispose() {
    _state.dispose();
    widget.api?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _state,
      child: MaterialApp(
        title: 'itsclear™',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const PhoneShell(),
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
    final subtitles = <String?>[
      state.isLive ? null : 'Lucknow, Uttar Pradesh',
      '${state.filteredProducts.length} stoneground flours',
      state.isLive ? 'Tracking & receipts' : 'Batch #IC-0426',
      '${state.cartCount} items',
      state.isLive ? 'Guest' : 'Verified member',
    ];

    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: appSystemBars,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          bottom: keyboardVisible,
          child: Column(
            children: [
              AppTopBar(
                title: state.isLive && state.tab == 0 ? 'Online store'
                    : state.isLive && state.tab == 2 ? 'Your orders' : _titles[state.tab],
                subtitle: subtitles[state.tab],
                showLogo: state.tab == 0,
                actions: _actions(context, state),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: IndexedStack(
                      sizing: StackFit.expand,
                      index: state.tab,
                      children: [
                        const HomeScreen(),
                        const ShopScreen(),
                        state.isLive ? const InAppOrdersTab() : const LabScreen(),
                        const CartScreen(),
                        const ProfileScreen(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: keyboardVisible
            ? null
            : SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: BottomDock(
                      selectedIndex: state.tab,
                      cartCount: state.cartCount,
                      showOrders: state.isLive,
                      onTap: (index) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        state.goTab(index);
                      },
                    ),
                  ),
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
        if (!state.isLive) ...[
          const SizedBox(width: 6),
          RoundIconButton(
            icon: Icons.notifications_none,
            onTap: () => pushScreen(context, const NotificationsScreen()),
          ),
        ],
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
      if (state.isLive) return [];
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
    if (state.isLive) return [];
    return [
      RoundIconButton(
        icon: Icons.notifications_none,
        onTap: () => pushScreen(context, const NotificationsScreen()),
      ),
    ];
  }
}
