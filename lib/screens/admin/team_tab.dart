import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'create_user_screen.dart';

/// Admin Team — who's an admin. Toggling the switch promotes/demotes a user
/// between 'clerk' and 'admin' (via the profiles_admin_update RLS policy).
class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  bool _loading = true;
  String? _error;
  List<TeamMember> _members = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await AdminService.team();
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _toggle(TeamMember m, bool makeAdmin) async {
    setState(() => _busyId = m.id);
    try {
      await AdminService.setRole(m.id, makeAdmin ? 'admin' : 'clerk');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update role. $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final myId = AuthService.currentUser?.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const CreateUserScreen()),
              );
              if (created == true) _load();
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add account'),
          ),
          const SizedBox(height: 16),
          Text(
            'Add a partner store or a TYC admin — an account is created with a '
            'password to share. The switch below flips an existing user between '
            'admin and clerk.',
            style: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final m in _members)
            _MemberRow(
              member: m,
              isSelf: m.id == myId,
              busy: _busyId == m.id,
              onToggle: (v) => _toggle(m, v),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isSelf,
    required this.busy,
    required this.onToggle,
  });

  final TeamMember member;
  final bool isSelf;
  final bool busy;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final name = (member.fullName?.isNotEmpty ?? false)
        ? member.fullName!
        : member.id.substring(0, 8);
    final subtitle = [
      if (member.partnerName != null) member.partnerName!,
      if (isSelf) 'You',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              member.isAdmin ? 'Admin' : 'Clerk',
              style: GoogleFonts.dmSans(
                color: member.isAdmin ? AppColors.accent : AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (busy)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Switch(
                value: member.isAdmin,
                // Don't let an admin demote themselves and risk lockout.
                onChanged: isSelf ? null : onToggle,
                activeColor: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
