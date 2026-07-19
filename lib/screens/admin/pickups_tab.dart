import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/intake_item.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_ui.dart';
import '../history/item_detail_screen.dart';
import '../history/item_row.dart';

/// Admin Pickups — every partner's trade-ins, grouped by store, filtered by
/// status. Defaults to "Awaiting pickup" (the items TYC owes stores for).
class PickupsTab extends StatefulWidget {
  const PickupsTab({super.key});

  @override
  State<PickupsTab> createState() => _PickupsTabState();
}

class _PickupsTabState extends State<PickupsTab> {
  static const _filters = <(String?, String)>[
    ('accepted', 'Awaiting pickup'),
    ('picked_up', 'Picked up'),
    ('settled', 'Settled'),
    (null, 'All'),
  ];

  String? _status = 'accepted';
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
      final items = await AdminService.items(status: _status);
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

  String _statusLabel(String? status) {
    for (final f in _filters) {
      if (f.$1 == status) return f.$2;
    }
    return 'Items';
  }

  /// Ordered grouping by partner (items already come newest-first).
  Map<String, List<IntakeItem>> get _byPartner {
    final map = <String, List<IntakeItem>>{};
    for (final item in _items) {
      final key = item.partnerName ?? 'Unknown store';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final total =
        _items.fold<double>(0, (sum, i) => sum + (i.offerValue ?? 0));
    final groups = _byPartner;

    return Column(
      children: [
        _FilterBar(
          filters: _filters,
          selected: _status,
          onSelect: (s) {
            setState(() => _status = s);
            _load();
          },
        ),
        Expanded(
          child: _buildBody(groups, total),
        ),
      ],
    );
  }

  Widget _buildBody(Map<String, List<IntakeItem>> groups, double total) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          StatCard(
            label: _status == 'accepted' ? 'Awaiting pickup' : _statusLabel(_status),
            amount: formatMoney(total),
            caption: _status == 'accepted'
                ? 'TYC owes ${groups.length} store${groups.length == 1 ? '' : 's'}'
                : '${groups.length} store${groups.length == 1 ? '' : 's'}',
            meta: '${_items.length} item${_items.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text('Nothing here.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            for (final entry in groups.entries) ...[
              _PartnerHeader(
                name: entry.key,
                count: entry.value.length,
                subtotal: entry.value
                    .fold<double>(0, (s, i) => s + (i.offerValue ?? 0)),
              ),
              const SizedBox(height: 8),
              for (final item in entry.value)
                IntakeItemRow(
                  item: item,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ItemDetailScreen(item: item, adminMode: true),
                      ),
                    );
                    _load(); // reflect any status change made in detail
                  },
                ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<(String?, String)> filters;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.$2),
                selected: selected == f.$1,
                onSelected: (_) => onSelect(f.$1),
                showCheckmark: false,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected == f.$1
                      ? const Color(0xFF07230A)
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: selected == f.$1 ? AppColors.accent : AppColors.border,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartnerHeader extends StatelessWidget {
  const _PartnerHeader({
    required this.name,
    required this.count,
    required this.subtotal,
  });

  final String name;
  final int count;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Text(
            '${formatMoney(subtotal)} · $count',
            style: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
