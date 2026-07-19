import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';

class StatusStyle {
  final String label;
  final Color color;
  const StatusStyle(this.label, this.color);
}

StatusStyle statusStyleFor(String status) {
  switch (status) {
    case 'accepted':
      return const StatusStyle('Accepted', AppColors.primary); // green
    case 'picked_up':
      return const StatusStyle('Picked up', AppColors.amber); // amber
    case 'settled':
      return const StatusStyle('Settled', Color(0xFF8A8A8A)); // gray
    default:
      return StatusStyle(status, const Color(0xFF8A8A8A));
  }
}

/// Status pill with a leading colored dot + Space Mono label.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleFor(status);
    return DotPill(label: style.label, color: style.color);
  }
}
