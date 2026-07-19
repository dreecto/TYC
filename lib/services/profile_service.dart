import 'auth_service.dart';

/// The signed-in clerk's partner context: which store they belong to and its
/// payout rate (used to compute the offer). Loaded once when the intake flow
/// opens.
class PartnerContext {
  final String partnerId;
  final String partnerName;
  final double payoutRate;
  final String? fullName;
  final String role;

  const PartnerContext({
    required this.partnerId,
    required this.partnerName,
    required this.payoutRate,
    this.fullName,
    this.role = 'clerk',
  });

  bool get isAdmin => role == 'admin';
}

class ProfileService {
  ProfileService._();

  static Future<PartnerContext> load() async {
    final client = AuthService.client;
    final userId = AuthService.currentUser!.id;

    final profile = await client
        .from('profiles')
        .select('partner_id, full_name, role')
        .eq('id', userId)
        .single();

    final partnerId = profile['partner_id'] as String;

    final partner = await client
        .from('partners')
        .select('name, payout_rate')
        .eq('id', partnerId)
        .single();

    return PartnerContext(
      partnerId: partnerId,
      partnerName: partner['name'] as String? ?? 'Your store',
      payoutRate: (partner['payout_rate'] as num?)?.toDouble() ?? 1.0,
      fullName: profile['full_name'] as String?,
      role: (profile['role'] as String?) ?? 'clerk',
    );
  }
}
