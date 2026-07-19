const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a date like `Jul 19, 2026`.
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// Formats a date + time like `Jul 19, 2026 · 3:07 PM`.
String formatDateTime(DateTime d) {
  final h24 = d.hour;
  final ampm = h24 < 12 ? 'AM' : 'PM';
  var h = h24 % 12;
  if (h == 0) h = 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)} · $h:$m $ampm';
}

/// Formats a dollar amount like `$1,234.50`.
String formatMoney(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  return '${negative ? '-' : ''}\$$buffer.${parts[1]}';
}
