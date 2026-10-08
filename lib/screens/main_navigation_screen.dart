import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_providers.dart';
import 'home/home_screen.dart';
import 'route_planner/route_map_screen.dart';
import 'daily_summary/daily_summary_screen.dart';
import 'ledger/shop_ledger_screen.dart';
import 'follow_ups/follow_ups_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      firestoreService.ensureUserAccountInitialized(
        user: user,
      );
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    RouteMapScreen(),
    DailySummaryScreen(),
    ShopLedgerScreen(),
    FollowUpsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Check pending follow-ups for badge
    final followUpsAsync = ref.watch(followUpsStreamProvider);
    final pendingCount = (followUpsAsync.valueOrNull ?? [])
        .where((f) => !f.isResolved && (f.isDueToday || f.isOverdue))
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded, color: AppColors.primary),
              label: 'Stores',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_rounded),
              activeIcon: Icon(Icons.alt_route_rounded, color: AppColors.primary),
              label: 'Trip Map',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
              label: 'Daily EOD',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded, color: AppColors.primary),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                backgroundColor: AppColors.danger,
                child: const Icon(Icons.notifications_none_rounded),
              ),
              activeIcon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                backgroundColor: AppColors.danger,
                child: const Icon(Icons.notifications_rounded, color: AppColors.primary),
              ),
              label: 'Follow-ups',
            ),
          ],
        ),
      ),
    );
  }
}
