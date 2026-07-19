import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/club_spec_config.dart';
import '../../models/intake_item.dart';
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'status_chip.dart';

/// Full detail for one trade-in: all photos, specs, condition, values,
/// timestamps, and signature. In [adminMode] it also shows the store name and
/// pickup/settle actions.
class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
    this.adminMode = false,
  });

  final IntakeItem item;
  final bool adminMode;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late IntakeItem _item;
  late Future<List<String>> _photos;
  late Future<String?> _signature;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _photos = StorageService.allPhotoUrls(_item.partnerId, _item.id);
    _signature = StorageService.signatureUrl(_item.partnerId, _item.id);
  }

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    try {
      await AdminService.setItemStatus(_item.id, status);
      setState(() {
        _item = IntakeItem(
          id: _item.id,
          partnerId: _item.partnerId,
          createdBy: _item.createdBy,
          brand: _item.brand,
          model: _item.model,
          category: _item.category,
          specs: _item.specs,
          condition: _item.condition,
          pgaValue: _item.pgaValue,
          offerValue: _item.offerValue,
          status: status,
          customerAcceptedAt: _item.customerAcceptedAt,
          createdAt: _item.createdAt,
          partnerName: _item.partnerName,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update status. $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final specFields = specsFor(item.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title.isEmpty ? 'Trade-in' : item.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _PhotoStrip(future: _photos),
          const SizedBox(height: 20),
          Row(
            children: [
              StatusChip(status: item.status),
              const Spacer(),
              Text(
                formatMoney(item.offerValue ?? 0),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (widget.adminMode) ...[
            const SizedBox(height: 12),
            _InfoCard(children: [
              _kv('Store', item.partnerName ?? '—'),
            ]),
          ],
          const SizedBox(height: 16),
          _InfoCard(children: [
            _kv('Category', categoryFor(item.category)?.label ?? item.category),
            _kv('Condition', conditionFor(item.condition)?.label ?? '—'),
            for (final f in specFields)
              if ((item.specs[f.key]?.toString().isNotEmpty ?? false))
                _kv(f.label, item.specs[f.key].toString()),
          ]),
          const SizedBox(height: 16),
          _InfoCard(children: [
            _kv('PGA value', formatMoney(item.pgaValue ?? 0)),
            _kv('Store credit offer', formatMoney(item.offerValue ?? 0)),
          ]),
          const SizedBox(height: 16),
          _InfoCard(children: [
            _kv('Customer accepted',
                item.customerAcceptedAt == null
                    ? '—'
                    : formatDateTime(item.customerAcceptedAt!)),
            _kv('Created', formatDateTime(item.createdAt)),
          ]),
          const SizedBox(height: 20),
          Text(
            'CUSTOMER SIGNATURE',
            style: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          _SignatureView(future: _signature),
          if (widget.adminMode) ...[
            const SizedBox(height: 24),
            _AdminActions(
              status: item.status,
              updating: _updating,
              onPickedUp: () => _setStatus('picked_up'),
              onSettled: () => _setStatus('settled'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              k,
              style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.dmSans(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.future});
  final Future<List<String>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final urls = snap.data ?? const [];
        if (urls.isEmpty) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('No photos',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }
        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                urls[i],
                width: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 240,
                  color: AppColors.surface,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignatureView extends StatelessWidget {
  const _SignatureView({required this.future});
  final Future<String?> future;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: FutureBuilder<String?>(
        future: future,
        builder: (context, snap) {
          final url = snap.data;
          if (url == null) {
            return const Text('No signature captured',
                style: TextStyle(color: AppColors.textMuted));
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Image.network(url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('No signature',
                    style: TextStyle(color: AppColors.textMuted))),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  const _AdminActions({
    required this.status,
    required this.updating,
    required this.onPickedUp,
    required this.onSettled,
  });

  final String status;
  final bool updating;
  final VoidCallback onPickedUp;
  final VoidCallback onSettled;

  @override
  Widget build(BuildContext context) {
    if (updating) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        if (status == 'accepted')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onPickedUp,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Mark picked up'),
            ),
          ),
        if (status == 'picked_up')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSettled,
              icon: const Icon(Icons.paid_outlined),
              label: const Text('Mark settled'),
            ),
          ),
        if (status == 'settled')
          const Expanded(
            child: Center(
              child: Text('Settled — paid to store',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
      ],
    );
  }
}
