import 'package:flutter/material.dart';

import '../../models/intake_item.dart';
import '../../services/auth_service.dart';
import '../../services/history_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_ui.dart';
import 'item_detail_screen.dart';
import 'item_row.dart';

/// HISTORY tab — this partner's trade-ins, newest first, with an
/// "awaiting pickup" summary header.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<IntakeItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ctx = await ProfileService.load();
      final items = await HistoryService.forPartner(ctx.partnerId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _items.where((i) => i.status == 'accepted').toList();
    final totalOwed =
        accepted.fold<double>(0, (sum, i) => sum + (i.offerValue ?? 0));

    return Scaffold(
      appBar: AppHeader(
        title: 'History',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.signOut(),
          ),
        ],
      ),
      body: _buildBody(accepted.length, totalOwed),
    );
  }

  Widget _buildBody(int acceptedCount, double totalOwed) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          StatCard(
            label: 'Awaiting pickup',
            amount: formatMoney(totalOwed),
            caption: 'TYC owes this store',
            meta: '$acceptedCount item${acceptedCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text('No trade-ins yet.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            for (final item in _items)
              IntakeItemRow(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
