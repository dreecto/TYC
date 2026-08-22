import 'package:flutter_test/flutter_test.dart';
import 'package:tyc_partner/utils/format.dart';

void main() {
  group('formatDate', () {
    test('renders Month D, YYYY', () {
      expect(formatDate(DateTime(2026, 7, 19)), 'Jul 19, 2026');
      expect(formatDate(DateTime(2026, 12, 25)), 'Dec 25, 2026');
    });
  });

  group('formatDateTime', () {
    test('renders 12-hour time with AM/PM', () {
      expect(formatDateTime(DateTime(2026, 7, 19, 15, 7)), 'Jul 19, 2026 · 3:07 PM');
      expect(formatDateTime(DateTime(2026, 7, 19, 9, 0)), 'Jul 19, 2026 · 9:00 AM');
    });

    test('midnight and noon are 12, not 0', () {
      expect(formatDateTime(DateTime(2026, 1, 2, 0, 0)), 'Jan 2, 2026 · 12:00 AM');
      expect(formatDateTime(DateTime(2026, 1, 2, 12, 0)), 'Jan 2, 2026 · 12:00 PM');
    });

    test('zero-pads the minutes', () {
      expect(formatDateTime(DateTime(2026, 1, 2, 4, 5)), 'Jan 2, 2026 · 4:05 AM');
    });
  });

  group('formatMoney', () {
    test('groups thousands and keeps two decimals', () {
      expect(formatMoney(1234.5), r'$1,234.50');
      expect(formatMoney(0), r'$0.00');
    });

    test('handles negatives', () {
      expect(formatMoney(-42.5), r'-$42.50');
    });
  });
}
