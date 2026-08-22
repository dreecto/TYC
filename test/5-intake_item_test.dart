import 'package:flutter_test/flutter_test.dart';
import 'package:tyc_partner/models/intake_item.dart';

Map<String, dynamic> _row({Map<String, dynamic>? partner, bool usePartnersKey = true}) {
  final m = <String, dynamic>{
    'id': 'i1',
    'partner_id': 'p1',
    'created_by': null,
    'brand': 'Ping',
    'model': 'G430',
    'category': 'driver',
    'specs': {'loft': '9'},
    'condition': 'good',
    'pga_value': 300,
    'offer_value': 210.5,
    'status': 'accepted',
    'customer_accepted_at': null,
    'created_at': '2026-07-19T21:48:10Z',
  };
  if (partner != null) {
    if (usePartnersKey) {
      m['partners'] = partner;
    } else {
      m['partner'] = partner;
    }
  }
  return m;
}

void main() {
  group('IntakeItem.fromMap', () {
    test('reads the partner embed under either key', () {
      final viaPartners = IntakeItem.fromMap(_row(partner: {'name': 'Coral Canyon'}, usePartnersKey: true));
      final viaPartner = IntakeItem.fromMap(_row(partner: {'name': 'Coral Canyon'}, usePartnersKey: false));
      expect(viaPartners.partnerName, 'Coral Canyon');
      expect(viaPartner.partnerName, 'Coral Canyon');
      expect(IntakeItem.fromMap(_row()).partnerName, isNull);
    });

    test('applies defaults and parses numbers/dates', () {
      final m = _row()
        ..remove('category')
        ..remove('status');
      final i = IntakeItem.fromMap(m);
      expect(i.category, 'other');
      expect(i.status, 'accepted');
      expect(i.pgaValue, 300);
      expect(i.offerValue, 210.5);
      final now = IntakeItem.fromMap(_row()..remove('created_at'));
      expect(DateTime.now().difference(now.createdAt).inMinutes, lessThan(1));
    });

    test('title trims and tolerates missing brand/model', () {
      expect(IntakeItem.fromMap(_row()).title, 'Ping G430');
      final m = _row()
        ..remove('brand')
        ..remove('model');
      expect(IntakeItem.fromMap(m).title, '');
    });
  });
}
