import '../models/intake_item.dart';
import 'auth_service.dart';

class HistoryService {
  HistoryService._();

  /// This partner's intake items, newest first.
  static Future<List<IntakeItem>> forPartner(String partnerId) async {
    final rows = await AuthService.client
        .from('intake_items')
        .select()
        .eq('partner_id', partnerId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => IntakeItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
