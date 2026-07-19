import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/intake_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Shown after a visit is saved. "New trade-in" resets the flow.
class ConfirmationView extends StatelessWidget {
  const ConfirmationView({super.key, required this.result, required this.onNew});

  final VisitResult result;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final count = result.items.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 88,
                width: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(Icons.check, size: 48, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              Text(
                'Trade-in saved',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count club${count == 1 ? '' : 's'} accepted as store credit.',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in result.items) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.dmSans(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(item.offer),
                            style: GoogleFonts.dmSans(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(height: 12, color: AppColors.border),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total store credit',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          formatMoney(result.total),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add),
                label: const Text('New trade-in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
