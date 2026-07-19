import 'dart:convert';

/// One club within a customer visit. Holds the per-club intake data.
class DraftItem {
  String? category;
  String? brand;
  String? model;
  Map<String, String> specs;
  String? condition; // like_new / good / fair
  String? pgaValueText; // raw text from the numeric field
  List<String> photoPaths;

  DraftItem({
    this.category,
    this.brand,
    this.model,
    Map<String, String>? specs,
    this.condition,
    this.pgaValueText,
    List<String>? photoPaths,
  })  : specs = specs ?? <String, String>{},
        photoPaths = photoPaths ?? <String>[];

  /// Parsed PGA value, or null if blank/invalid. Strips $ and commas.
  double? get pgaValue {
    final raw = pgaValueText;
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String get title => '${brand ?? ''} ${model ?? ''}'.trim();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'category': category,
        'brand': brand,
        'model': model,
        'specs': specs,
        'condition': condition,
        'pgaValueText': pgaValueText,
        'photoPaths': photoPaths,
      };

  factory DraftItem.fromJson(Map<String, dynamic> json) => DraftItem(
        category: json['category'] as String?,
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        specs: (json['specs'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            <String, String>{},
        condition: json['condition'] as String?,
        pgaValueText: json['pgaValueText'] as String?,
        photoPaths: (json['photoPaths'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
      );

  DraftItem copy() => DraftItem.fromJson(toJson());
}

/// The in-progress customer visit: one or more clubs plus visit-level
/// acceptance. Serialized to shared_preferences after every change so a crash
/// or backgrounding never loses the entry. Photo file paths survive
/// backgrounding; the signature bitmap is re-drawn at the acceptance step.
class TradeInDraft {
  /// Clubs already added to this visit.
  List<DraftItem> items;

  /// The club currently being built, or null when viewing the visit list.
  DraftItem? editing;

  /// Step within the per-club sub-flow: 0 details, 1 condition, 2 value,
  /// 3 photos.
  int editStep;

  /// 0 = visit item list, 1 = acceptance.
  int phase;

  bool customerAccepts;

  TradeInDraft({
    List<DraftItem>? items,
    this.editing,
    this.editStep = 0,
    this.phase = 0,
    this.customerAccepts = false,
  }) : items = items ?? <DraftItem>[];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'items': items.map((i) => i.toJson()).toList(),
        'editing': editing?.toJson(),
        'editStep': editStep,
        'phase': phase,
        'customerAccepts': customerAccepts,
      };

  factory TradeInDraft.fromJson(Map<String, dynamic> json) => TradeInDraft(
        items: (json['items'] as List?)
                ?.map((e) => DraftItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <DraftItem>[],
        editing: json['editing'] == null
            ? null
            : DraftItem.fromJson(json['editing'] as Map<String, dynamic>),
        editStep: json['editStep'] as int? ?? 0,
        phase: json['phase'] as int? ?? 0,
        customerAccepts: json['customerAccepts'] as bool? ?? false,
      );

  String encode() => jsonEncode(toJson());

  static TradeInDraft decode(String source) =>
      TradeInDraft.fromJson(jsonDecode(source) as Map<String, dynamic>);

  bool get isEmpty => items.isEmpty && editing == null;

  /// Every photo path referenced anywhere in the visit (for cleanup).
  List<String> get allPhotoPaths => [
        for (final i in items) ...i.photoPaths,
        if (editing != null) ...editing!.photoPaths,
      ];
}
