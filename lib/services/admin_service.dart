import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/intake_item.dart';
import 'auth_service.dart';

/// A user row for the admin Team section.
class TeamMember {
  final String id;
  final String? fullName;
  final String role;
  final String? partnerName;

  const TeamMember({
    required this.id,
    required this.fullName,
    required this.role,
    required this.partnerName,
  });

  bool get isAdmin => role == 'admin';
}

/// Cross-partner reads/writes for TYC admins. Every call here relies on the
/// is_admin() RLS policies from migration2_admin.sql.
class AdminService {
  AdminService._();

  /// All intake items (optionally filtered by status), newest first, with the
  /// partner name embedded.
  static Future<List<IntakeItem>> items({String? status}) async {
    final base = AuthService.client
        .from('intake_items')
        .select('*, partners(name)');
    final filtered = status == null ? base : base.eq('status', status);
    final rows = await filtered.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => IntakeItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Number of items awaiting pickup across all partners (the notification).
  static Future<int> pendingPickupCount() async {
    final rows = await AuthService.client
        .from('intake_items')
        .select('id')
        .eq('status', 'accepted');
    return (rows as List).length;
  }

  static Future<void> setItemStatus(String itemId, String status) async {
    await AuthService.client
        .from('intake_items')
        .update({'status': status}).eq('id', itemId);
  }

  static Future<List<TeamMember>> team() async {
    final rows = await AuthService.client
        .from('profiles')
        .select('id, full_name, role, partners(name)')
        .order('role', ascending: true);
    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      final partner = m['partners'] as Map<String, dynamic>?;
      return TeamMember(
        id: m['id'] as String,
        fullName: m['full_name'] as String?,
        role: (m['role'] as String?) ?? 'clerk',
        partnerName: partner?['name'] as String?,
      );
    }).toList();
  }

  static Future<void> setRole(String userId, String role) async {
    await AuthService.client
        .from('profiles')
        .update({'role': role}).eq('id', userId);
  }

  /// Creates a login account via the admin-create-user Edge Function.
  /// [payload] must include `type` ('partner'|'admin'), `email`, the partner
  /// fields for a partner, and `invite` (true = email a set-password link,
  /// false = generate a password to share). Throws a readable message on error.
  static Future<CreatedUser> createUser(Map<String, dynamic> payload) async {
    try {
      final res = await AuthService.client.functions
          .invoke('admin-create-user', body: payload);
      final data = (res.data as Map).cast<String, dynamic>();
      return CreatedUser(
        email: data['email'] as String,
        password: data['password'] as String?,
        invited: data['invited'] == true,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'Could not create the account.';
      throw Exception(msg);
    }
  }
}

/// Result of creating an account. [password] is set only when a password was
/// generated to share; [invited] is true when an email invite was sent.
class CreatedUser {
  final String email;
  final String? password;
  final bool invited;
  const CreatedUser({
    required this.email,
    required this.password,
    required this.invited,
  });
}
