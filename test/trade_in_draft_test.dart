import 'package:flutter_test/flutter_test.dart';
import 'package:tyc_partner/models/trade_in_draft.dart';

void main() {
  group('DraftItem.pgaValue', () {
    test('parses currency-ish text', () {
      expect(DraftItem(pgaValueText: r'$1,234.50').pgaValue, 1234.50);
      expect(DraftItem(pgaValueText: '350').pgaValue, 350.0);
    });

    test('blank, absent, or garbage becomes null', () {
      expect(DraftItem().pgaValue, isNull);
      expect(DraftItem(pgaValueText: '').pgaValue, isNull);
      expect(DraftItem(pgaValueText: 'abc').pgaValue, isNull);
    });
  });

  group('DraftItem json round trip', () {
    test('preserves every field', () {
      final original = DraftItem(
        category: 'driver',
        brand: 'Callaway',
        model: 'Elyte X',
        specs: {'loft': '9.0', 'shaft': 'Ventus'},
        condition: 'good',
        pgaValueText: '425',
        photoPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      );
      final restored = DraftItem.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
    });

    test('copy is independent of the source', () {
      final original = DraftItem(specs: {'loft': '9'}, photoPaths: ['/tmp/a.jpg']);
      final clone = original.copy();
      clone.specs['loft'] = '10.5';
      clone.photoPaths.add('/tmp/c.jpg');
      expect(original.specs['loft'], '9');
      expect(original.photoPaths.length, 1);
    });
  });

  group('TradeInDraft', () {
    test('encode/decode round trip', () {
      final draft = TradeInDraft(
        items: [DraftItem(brand: 'Ping', model: 'G430')],
        editing: DraftItem(brand: 'Callaway'),
        editStep: 2,
        phase: 1,
        customerAccepts: true,
      );
      final restored = TradeInDraft.decode(draft.encode());
      expect(restored.items.single.brand, 'Ping');
      expect(restored.editing?.brand, 'Callaway');
      expect(restored.editStep, 2);
      expect(restored.phase, 1);
      expect(restored.customerAccepts, isTrue);
    });

    test('isEmpty only when nothing is in flight', () {
      expect(TradeInDraft().isEmpty, isTrue);
      expect(TradeInDraft(items: [DraftItem()]).isEmpty, isFalse);
      expect(TradeInDraft(editing: DraftItem()).isEmpty, isFalse);
    });

    test('allPhotoPaths covers items and the in-progress club', () {
      final draft = TradeInDraft(
        items: [DraftItem(photoPaths: ['/tmp/saved.jpg'])],
        editing: DraftItem(photoPaths: ['/tmp/editing.jpg']),
      );
      expect(draft.allPhotoPaths, containsAll(['/tmp/saved.jpg', '/tmp/editing.jpg']));
    });
  });
}
