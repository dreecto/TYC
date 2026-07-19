import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/trade_in_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';

/// Step 3 — PGA value input + auto-computed, display-only offer.
class StepValue extends StatefulWidget {
  const StepValue({
    super.key,
    required this.draft,
    required this.payoutRate,
    required this.onChanged,
  });

  final DraftItem draft;
  final double payoutRate;
  final VoidCallback onChanged;

  @override
  State<StepValue> createState() => _StepValueState();
}

class _StepValueState extends State<StepValue> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft.pgaValueText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pga = widget.draft.pgaValue ?? 0;
    final offer = pga * widget.payoutRate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text(
          'PGA Value Guide amount',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the value you looked up in the Check Value tab.',
          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          decoration: const InputDecoration(
            prefixText: r'$ ',
            prefixStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            hintText: '0',
          ),
          onChanged: (v) {
            widget.draft.pgaValueText = v;
            widget.onChanged();
            setState(() {});
          },
        ),
        const SizedBox(height: 32),
        // Bone card — a premium, customer-facing moment.
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bone,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.boneDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUTHORIZED STORE CREDIT OFFER',
                style: GoogleFonts.spaceMono(
                  color: AppColors.onBone.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                formatMoney(offer),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'PGA value ${formatMoney(pga)} × payout rate '
                '${widget.payoutRate.toStringAsFixed(2)}. This offer is set '
                'automatically and cannot be edited.',
                style: GoogleFonts.dmSans(
                  color: AppColors.onBone.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
