import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/intake_item.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'status_chip.dart';

/// A single trade-in row: thumbnail, brand + model, offer, status chip.
class IntakeItemRow extends StatefulWidget {
  const IntakeItemRow({
    super.key,
    required this.item,
    required this.onTap,
    this.showPartner = false,
  });

  final IntakeItem item;
  final VoidCallback onTap;
  final bool showPartner;

  @override
  State<IntakeItemRow> createState() => _IntakeItemRowState();
}

class _IntakeItemRowState extends State<IntakeItemRow> {
  late final Future<String?> _thumb;

  @override
  void initState() {
    super.initState();
    _thumb = StorageService.firstPhotoUrl(
      widget.item.partnerId,
      widget.item.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final subtitle = widget.showPartner
        ? (item.partnerName ?? 'Unknown store')
        : formatDate(item.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(future: _thumb),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Untitled club' : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatMoney(item.offerValue ?? 0),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StatusChip(status: item.status),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.future});
  final Future<String?> future;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 64,
        width: 64,
        child: FutureBuilder<String?>(
          future: future,
          builder: (context, snap) {
            final url = snap.data;
            if (url == null) {
              return Container(
                color: AppColors.ground,
                child: const Icon(Icons.sports_golf,
                    color: AppColors.textMuted, size: 26),
              );
            }
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.ground,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textMuted, size: 22),
              ),
            );
          },
        ),
      ),
    );
  }
}
