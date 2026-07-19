import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';

import '../../../data/club_spec_config.dart';
import '../../../models/trade_in_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';

/// Acceptance — one combined summary for the whole visit, one checkbox, one
/// signature covering every club.
class StepAcceptance extends StatelessWidget {
  const StepAcceptance({
    super.key,
    required this.items,
    required this.payoutRate,
    required this.sigController,
    required this.customerAccepts,
    required this.onToggleAccept,
  });

  final List<DraftItem> items;
  final double payoutRate;
  final SignatureController sigController;
  final bool customerAccepts;
  final VoidCallback onToggleAccept;

  double _offer(DraftItem i) => (i.pgaValue ?? 0) * payoutRate;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, i) => sum + _offer(i));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bone,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.boneDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${items.length} club${items.length == 1 ? '' : 's'} in this visit',
                style: GoogleFonts.spaceMono(
                  color: AppColors.onBone.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              for (final item in items) ...[
                _ItemLine(
                  title: item.title.isEmpty ? 'Untitled club' : item.title,
                  subtitle: [
                    categoryFor(item.category)?.label,
                    conditionFor(item.condition)?.label,
                  ].whereType<String>().join(' · '),
                  offer: _offer(item),
                ),
                const SizedBox(height: 10),
              ],
              const Divider(height: 12, color: AppColors.boneDivider),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total store credit offer',
                    style: GoogleFonts.dmSans(
                      color: AppColors.onBone.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    formatMoney(total),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AcceptCheckbox(value: customerAccepts, onToggle: onToggleAccept),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CUSTOMER SIGNATURE',
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            TextButton.icon(
              onPressed: () => sigController.clear(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Signature(
              controller: sigController,
              height: 200,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One signature covers all ${items.length} club'
          '${items.length == 1 ? '' : 's'} above.',
          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({
    required this.title,
    required this.subtitle,
    required this.offer,
  });

  final String title;
  final String subtitle;
  final double offer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBone,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.onBone.withValues(alpha: 0.55),
                    fontSize: 12.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(offer),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onBone,
          ),
        ),
      ],
    );
  }
}

class _AcceptCheckbox extends StatelessWidget {
  const _AcceptCheckbox({required this.value, required this.onToggle});

  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? AppColors.primary.withValues(alpha: 0.14) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? AppColors.accent : AppColors.border,
              width: value ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                color: value ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Customer accepts this offer as store credit',
                  style: GoogleFonts.dmSans(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
