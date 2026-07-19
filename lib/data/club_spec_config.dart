import 'package:flutter/material.dart';

/// Category, spec-field, and condition configuration for the intake flow.
/// Kept declarative so Step 1's form and Step 5's summary stay in sync.

class ClubCategory {
  final String value; // stored in DB (matches the CHECK constraint)
  final String label;
  final IconData icon;
  const ClubCategory(this.value, this.label, this.icon);
}

/// Order matters — this is the tile order in Step 1.
const List<ClubCategory> kCategories = <ClubCategory>[
  ClubCategory('driver', 'Driver', Icons.sports_golf),
  ClubCategory('fairway', 'Fairway', Icons.golf_course),
  ClubCategory('hybrid', 'Hybrid', Icons.merge_type),
  ClubCategory('iron_set', 'Iron Set', Icons.view_module),
  ClubCategory('wedge', 'Wedge', Icons.change_history),
  ClubCategory('putter', 'Putter', Icons.stroller),
  ClubCategory('other', 'Other', Icons.more_horiz),
];

ClubCategory? categoryFor(String? value) {
  for (final c in kCategories) {
    if (c.value == value) return c;
  }
  return null;
}

enum SpecFieldType { text, choice }

class SpecField {
  final String key; // key inside intake_items.specs jsonb
  final String label;
  final SpecFieldType type;
  final List<String> options; // for choice
  final bool required;
  final String? hint;
  final bool numeric; // hint a number pad for text fields
  const SpecField({
    required this.key,
    required this.label,
    this.type = SpecFieldType.text,
    this.options = const <String>[],
    this.required = false,
    this.hint,
    this.numeric = false,
  });
}

const List<String> kFlexOptions = <String>[
  'Regular',
  'Stiff',
  'X-Stiff',
  'Senior',
  'Ladies',
];

const List<String> kDexterityOptions = <String>['Right', 'Left'];

const SpecField _loft = SpecField(
  key: 'loft',
  label: 'Loft',
  hint: 'e.g. 10.5°',
  numeric: true,
);
const SpecField _shaft = SpecField(
  key: 'shaft',
  label: 'Shaft',
  hint: 'e.g. Ventus Blue 6',
);
const SpecField _flex = SpecField(
  key: 'flex',
  label: 'Flex',
  type: SpecFieldType.choice,
  options: kFlexOptions,
  required: true,
);
const SpecField _dexterity = SpecField(
  key: 'dexterity',
  label: 'Dexterity',
  type: SpecFieldType.choice,
  options: kDexterityOptions,
  required: true,
);

/// Spec fields shown for each category (Step 1, conditional section).
const Map<String, List<SpecField>> kSpecsByCategory = <String, List<SpecField>>{
  'driver': <SpecField>[_loft, _shaft, _flex, _dexterity],
  'fairway': <SpecField>[_loft, _shaft, _flex, _dexterity],
  'hybrid': <SpecField>[_loft, _shaft, _flex, _dexterity],
  'iron_set': <SpecField>[
    SpecField(key: 'set_composition', label: 'Set composition', hint: 'e.g. 4–PW'),
    _shaft,
    _flex,
    _dexterity,
  ],
  'wedge': <SpecField>[
    _loft,
    SpecField(key: 'bounce', label: 'Bounce', hint: 'e.g. 10°', numeric: true),
    _dexterity,
  ],
  'putter': <SpecField>[
    SpecField(key: 'length', label: 'Length', hint: 'e.g. 34"', numeric: true),
    _dexterity,
  ],
  'other': <SpecField>[
    SpecField(key: 'note', label: 'Notes', hint: 'Anything worth recording'),
  ],
};

List<SpecField> specsFor(String? category) =>
    kSpecsByCategory[category] ?? const <SpecField>[];

class ConditionGrade {
  final String value; // like_new / good / fair
  final String label;
  final String description;
  const ConditionGrade(this.value, this.label, this.description);
}

/// Grading language kept consistent with the PGA Value Guide's condition tiers.
const List<ConditionGrade> kConditions = <ConditionGrade>[
  ConditionGrade(
    'like_new',
    'Like New',
    'Minimal to no wear — no scratches on the face or sole, near-flawless cosmetics.',
  ),
  ConditionGrade(
    'good',
    'Good',
    'Normal wear from regular play — light scratches or bag chatter, fully playable.',
  ),
  ConditionGrade(
    'fair',
    'Fair',
    'Heavy or noticeable wear — significant scratches, marks, or sky marks, still functional.',
  ),
];

ConditionGrade? conditionFor(String? value) {
  for (final c in kConditions) {
    if (c.value == value) return c;
  }
  return null;
}
