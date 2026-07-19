import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import 'pickups_tab.dart';
import 'team_tab.dart';

/// ADMIN tab — TYC-only. Two sections: Pickups (every store's trade-ins /
/// what TYC owes, with photos) and Team (who is an admin).
///
/// This lives in the same app as the clerk tabs; it just appears as an extra
/// bottom-nav tab when the signed-in user's profile role is 'admin'.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(
            children: [
              const Icon(kTradeIcon, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Text(
                'Admin',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService.signOut(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14, left: 4),
              child: BrandAvatar(
                initial: (AuthService.currentUser?.email ?? 'T').isNotEmpty
                    ? (AuthService.currentUser?.email ?? 'T')[0]
                    : 'T',
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.text,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Pickups'),
              Tab(text: 'Team'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PickupsTab(),
            TeamTab(),
          ],
        ),
      ),
    );
  }
}
