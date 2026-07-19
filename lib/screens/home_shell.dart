import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'admin/admin_screen.dart';
import 'check_value_screen.dart';
import 'history/history_screen.dart';
import 'new_trade_in/new_trade_in_screen.dart';

/// The signed-in shell: bottom nav. Clerks get 3 tabs; admins get a 4th
/// (Admin) — decided from the profile role, so the admin portal lives inside
/// the same app rather than a separate place.
///
/// Tabs are kept alive via an [IndexedStack] so the WebView doesn't reload
/// every time the user switches tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _isAdmin = false;
  int _pendingPickups = 0;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final ctx = await ProfileService.load();
      var pending = 0;
      if (ctx.isAdmin) {
        pending = await AdminService.pendingPickupCount();
      }
      if (!mounted) return;
      setState(() {
        _isAdmin = ctx.isAdmin;
        _pendingPickups = pending;
      });
    } catch (_) {
      // Non-fatal: fall back to the clerk tab set.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tab order is fixed; New Trade-In (index 1) is the green flag FAB.
    final tabs = <Widget>[
      const CheckValueScreen(), // 0
      const NewTradeInScreen(), // 1 (FAB)
      const HistoryScreen(), // 2
      if (_isAdmin) const AdminScreen(), // 3
    ];

    // Pill holds the non-FAB destinations.
    final pillItems = <NavPillItem>[
      const NavPillItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        index: 0,
      ),
      const NavPillItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        index: 2,
      ),
      if (_isAdmin)
        NavPillItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          index: 3,
          badge: _pendingPickups,
        ),
    ];

    // Keep the index in range if the tab set shrank (role load failed).
    final safeIndex = _index >= tabs.length ? 0 : _index;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: FloatingNavBar(
        items: pillItems,
        currentIndex: safeIndex,
        onSelect: (i) => setState(() => _index = i),
        fabActive: safeIndex == 1,
        onFab: () => setState(() => _index = 1),
      ),
    );
  }
}
