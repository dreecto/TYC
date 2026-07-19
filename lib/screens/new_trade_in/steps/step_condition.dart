import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/club_spec_config.dart';
import '../../../models/trade_in_draft.dart';
import '../../../theme/app_theme.dart';

/// Step 2 — three large condition cards with PGA-consistent grading language.
class StepCondition extends StatelessWidget {
  const StepCondition({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final DraftItem draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          'How would you grade this club?',
          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 15),
        ),
        const SizedBox(height: 20),
        for (final grade in kConditions)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ConditionCard(
              grade: grade,
              selected: draft.condition == grade.value,
              onTap: () {
                draft.condition = grade.value;
                onChanged();
              },
            ),
          ),
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  final ConditionGrade grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.16) : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      grade.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
