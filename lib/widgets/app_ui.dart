import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Brand glyph for trade-in / swap — used on the header and the FAB.
const IconData kTradeIcon = Icons.swap_horiz;

/// Uppercase, letter-spaced Space Mono section label (e.g. "QUICK ACTIONS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color ?? AppColors.textMuted,
      ),
    );
  }
}

/// Small Space Mono metadata (handles, ids, hcp-style values).
class MonoMeta extends StatelessWidget {
  const MonoMeta(this.text, {super.key, this.color, this.size = 12});
  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: size,
        letterSpacing: 0.5,
        color: color ?? AppColors.textMuted,
      ),
    );
  }
}

/// Green circular avatar with an initial.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({super.key, required this.initial, this.size = 36});
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF07230A),
        ),
      ),
    );
  }
}

/// Branded top bar: green flag + Space Grotesk title, actions, then a green
/// avatar. Drop-in AppBar replacement for the top-level tab screens.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showAvatar = true,
  });

  final String title;
  final List<Widget> actions;
  final bool showAvatar;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0] : 'T';
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          const Icon(kTradeIcon, color: AppColors.accent, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: BrandAvatar(initial: initial),
          ),
      ],
    );
  }
}

/// A status pill with a leading colored dot and a Space Mono label.
class DotPill extends StatelessWidget {
  const DotPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium "financial" card: near-black panel, mono label with a status dot,
/// a large accent-green amount, and a caption. Used for balance/owed figures.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.caption,
    this.meta,
    this.accent = AppColors.accent,
  });

  final String label;
  final String amount;
  final String caption;
  final String? meta;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: SectionLabel(label)),
              if (meta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: MonoMeta(meta!, size: 11),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            caption,
            style: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// One destination in the floating pill nav.
class NavPillItem {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int badge;
  const NavPillItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    this.badge = 0,
  });
}

/// Floating white pill nav with a green flag FAB on the right.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.fabActive,
    required this.onFab,
  });

  final List<NavPillItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool fabActive;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.pill,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final item in items)
                      _PillIcon(
                        item: item,
                        active: currentIndex == item.index,
                        onTap: () => onSelect(item.index),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onFab,
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fabActive ? AppColors.text : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(kTradeIcon, color: Color(0xFF07230A), size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavPillItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? item.activeIcon : item.icon,
              color: active ? AppColors.primary : const Color(0xFF3A3A3A),
              size: 24,
            ),
          ),
          if (item.badge > 0)
            Positioned(
              top: 4,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${item.badge}',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF0E0E0E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
