import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/club_spec_config.dart';
import '../../../data/golf_brands.dart';
import '../../../models/trade_in_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/category_icon.dart';

/// Step 1 — category tiles, brand autocomplete, model, conditional specs.
class StepItemDetails extends StatefulWidget {
  const StepItemDetails({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final DraftItem draft;
  final VoidCallback onChanged;

  @override
  State<StepItemDetails> createState() => _StepItemDetailsState();
}

class _StepItemDetailsState extends State<StepItemDetails> {
  late final TextEditingController _modelController;
  final Map<String, TextEditingController> _specControllers = {};

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.draft.model ?? '');
  }

  @override
  void dispose() {
    _modelController.dispose();
    for (final c in _specControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _specController(String key) {
    return _specControllers.putIfAbsent(
      key,
      () => TextEditingController(text: widget.draft.specs[key] ?? ''),
    );
  }

  void _selectCategory(String value) {
    widget.draft.category = value;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final specs = specsFor(widget.draft.category);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _SectionLabel('Category'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            for (final cat in kCategories)
              _CategoryTile(
                category: cat,
                selected: widget.draft.category == cat.value,
                onTap: () => _selectCategory(cat.value),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionLabel('Brand'),
        const SizedBox(height: 12),
        _BrandField(
          initial: widget.draft.brand ?? '',
          onChanged: (v) {
            widget.draft.brand = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Model'),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'e.g. Stealth 2 Plus'),
          onChanged: (v) {
            widget.draft.model = v;
            widget.onChanged();
          },
        ),
        if (specs.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionLabel('Specs'),
          const SizedBox(height: 4),
          for (final field in specs) _buildSpecField(field),
        ],
      ],
    );
  }

  Widget _buildSpecField(SpecField field) {
    if (field.type == SpecFieldType.choice) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label + (field.required ? ' *' : ''),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final opt in field.options)
                  _ChoicePill(
                    label: opt,
                    selected: widget.draft.specs[field.key] == opt,
                    onTap: () {
                      widget.draft.specs[field.key] = opt;
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextField(
        controller: _specController(field.key),
        keyboardType: field.numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: field.numeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,°"\- ]'))]
            : null,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          hintText: field.hint,
        ),
        onChanged: (v) {
          widget.draft.specs[field.key] = v;
          widget.onChanged();
        },
      ),
    );
  }
}

class _BrandField extends StatelessWidget {
  const _BrandField({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initial),
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return kGolfBrands.where((b) => b.toLowerCase().contains(q));
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            hintText: 'Start typing… e.g. Titleist',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onChanged,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final opt in options)
                    ListTile(
                      title: Text(
                        opt,
                        style: const TextStyle(color: AppColors.text),
                      ),
                      onTap: () => onSelected(opt),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ClubCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.16) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIcon(
                category: category.value,
                size: 32,
                color: selected ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.text : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF07230A) : AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
