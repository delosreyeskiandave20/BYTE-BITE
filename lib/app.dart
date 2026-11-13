import 'package:flutter/material.dart';

import 'data/shop_store.dart';
import 'screens/auth_page.dart';
import 'screens/catalog_page.dart';
import 'screens/identify_page.dart';
import 'screens/home_page.dart';
import 'screens/motorcycle_browse_page.dart';
import 'screens/motorcycle_parts_catalog_page.dart';
import 'screens/parts_catalog_page.dart';
import 'screens/search_page.dart';
import 'screens/shop_page.dart';
import 'screens/shop_owner_dashboard_page.dart';
import 'theme/app_theme.dart';
import 'widgets/desktop_phone_frame.dart';
import 'widgets/home_bottom_navigation.dart';

/// Root app widget.
class MotoScanApp extends StatelessWidget {
  const MotoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _MotoScanShell(),
      builder: (context, child) =>
          DesktopPhoneFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Shell widget for the main app (shown after authentication)
class _MotoScanShell extends StatefulWidget {
  const _MotoScanShell();

  @override
  State<_MotoScanShell> createState() => _MotoScanShellState();
}

class _MotoScanShellState extends State<_MotoScanShell> {
  static const _homeTabIndex = 0;

  int _selectedIndex = _homeTabIndex;
  final _shopStore = ShopStore();
  final _homeScrollController = ScrollController();

  @override
  void dispose() {
    _homeScrollController.dispose();
    _shopStore.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    // Re-selecting Home returns the feed to the top, a familiar mobile pattern.
    if (index == _homeTabIndex && _selectedIndex == _homeTabIndex) {
      if (_homeScrollController.hasClients) {
        _homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openCategory(BuildContext context, String categoryId) {
    if (categoryId == 'accessories' || categoryId == 'maintenance') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CatalogPage(
            type: categoryId,
            shopStore: _shopStore,
            onOwnerSignIn: _openOwnerSignIn,
          ),
        ),
      );
      return;
    }

    final motorcycleCategory = switch (categoryId) {
      'engine' => 'Engine',
      'electrical' => 'Electrical',
      'suspension' => 'Suspension',
      'wheels' => 'Wheels & Tires',
      'body' => 'Body',
      _ => null,
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => motorcycleCategory == null
            ? PartsCatalogPage(
                categoryId: categoryId,
                shopStore: _shopStore,
                onOwnerSignIn: _openOwnerSignIn,
              )
            : MotorcyclePartsCatalogPage(
                initialCategory: motorcycleCategory,
                shopStore: _shopStore,
                onOwnerSignIn: _openOwnerSignIn,
              ),
      ),
    );
  }

  void _openMotorcycleBrowser(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MotorcycleBrowsePage()),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(
          shopStore: _shopStore,
          onOwnerSignIn: _openOwnerSignIn,
          onOpenShop: () {
            Navigator.of(context).pop();
            _selectTab(2);
          },
        ),
      ),
    );
  }

  Future<void> _openOwnerSignIn() async {
    final store = _shopStore;
    final signedInEmail = store.signedInEmail;

    // Firebase keeps the owner session across restarts; go straight to the
    // dashboard instead of asking for credentials again.
    if (signedInEmail != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ShopOwnerDashboardPage(
            store: store,
            ownerEmail: signedInEmail,
            onDone: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (authContext) => MotoScanAuthPage(
          onLogin: (email, password) =>
              store.signIn(email: email, password: password),
          onCreateAccount: (name, email, password) =>
              store.createOwner(name: name, email: email, password: password),
          onForgotPassword: store.sendPasswordResetEmail,
          onAuthenticated: (email) async {
            if (!authContext.mounted) return;
            Navigator.of(authContext).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => ShopOwnerDashboardPage(
                  store: store,
                  ownerEmail: email,
                  onDone: () => Navigator.of(context).pop(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // On Scan or Shop, system back returns to Home instead of closing the app.
      canPop: _selectedIndex == _homeTabIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _selectedIndex == _homeTabIndex) return;
        setState(() => _selectedIndex = _homeTabIndex);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            MotoScanHomePage(
              onSearch: _openSearch,
              onOwnerSignIn: _openOwnerSignIn,
              onCategorySelected: (category) =>
                  _openCategory(context, category),
              onViewMotorcycles: () => _openMotorcycleBrowser(context),
              shopStore: _shopStore,
              scrollController: _homeScrollController,
            ),
            IdentifyPage(onSearchParts: _openSearch),
            ShopPage(store: _shopStore, onOwnerSignIn: _openOwnerSignIn),
          ],
        ),
        bottomNavigationBar: HomeBottomNavigation(
          currentIndex: _selectedIndex,
          onTabSelected: _selectTab,
        ),
      ),
    );
  }
}
