import 'package:flutter/material.dart';

import '../widgets/placeholder_screen.dart';

/// HISTORY tab — past trade-ins and settlement batches. Placeholder for now.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'History',
      icon: Icons.receipt_long_outlined,
      message: 'Past trade-ins and settlement batches show up here.',
    );
  }
}
