/// A saved trade-in row from intake_items (optionally with the partner name
/// embedded, for the admin view).
class IntakeItem {
  final String id;
  final String partnerId;
  final String? createdBy;
  final String? brand;
  final String? model;
  final String category;
  final Map<String, dynamic> specs;
  final String? condition;
  final double? pgaValue;
  final double? offerValue;
  final String status; // accepted / picked_up / settled
  final DateTime? customerAcceptedAt;
  final DateTime createdAt;
  final String? partnerName;

  IntakeItem({
    required this.id,
    required this.partnerId,
    required this.createdBy,
    required this.brand,
    required this.model,
    required this.category,
    required this.specs,
    required this.condition,
    required this.pgaValue,
    required this.offerValue,
    required this.status,
    required this.customerAcceptedAt,
    required this.createdAt,
    required this.partnerName,
  });

  factory IntakeItem.fromMap(Map<String, dynamic> m) {
    // Embedded partner may arrive under `partners` (implicit) or `partner`.
    final partner = (m['partners'] ?? m['partner']) as Map<String, dynamic>?;
    return IntakeItem(
      id: m['id'] as String,
      partnerId: m['partner_id'] as String,
      createdBy: m['created_by'] as String?,
      brand: m['brand'] as String?,
      model: m['model'] as String?,
      category: (m['category'] as String?) ?? 'other',
      specs: (m['specs'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      condition: m['condition'] as String?,
      pgaValue: (m['pga_value'] as num?)?.toDouble(),
      offerValue: (m['offer_value'] as num?)?.toDouble(),
      status: (m['status'] as String?) ?? 'accepted',
      customerAcceptedAt: _date(m['customer_accepted_at']),
      createdAt: _date(m['created_at']) ?? DateTime.now(),
      partnerName: partner?['name'] as String?,
    );
  }

  String get title => '${brand ?? ''} ${model ?? ''}'.trim();

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }
}
