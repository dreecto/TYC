import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';

import '../../data/club_spec_config.dart';
import '../../models/trade_in_draft.dart';
import '../../services/draft_store.dart';
import '../../services/intake_service.dart';
import '../../services/photo_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_ui.dart';
import 'confirmation_view.dart';
import 'steps/step_acceptance.dart';
import 'steps/step_condition.dart';
import 'steps/step_item_details.dart';
import 'steps/step_photos.dart';
import 'steps/step_value.dart';

/// NEW TRADE-IN — a customer visit that can hold several clubs.
///
/// Flow: build a club through a 4-step sub-flow → it joins the visit list →
/// add more or Review & accept → one combined offer + one signature saves the
/// whole visit. Draft state persists after every change.
class NewTradeInScreen extends StatefulWidget {
  const NewTradeInScreen({super.key});

  @override
  State<NewTradeInScreen> createState() => _NewTradeInScreenState();
}

class _NewTradeInScreenState extends State<NewTradeInScreen> {
  static const _subStepTitles = <String>[
    'Item details',
    'Condition',
    'Value',
    'Photos',
  ];

  bool _loading = true;
  String? _error;
  bool _submitting = false;

  PartnerContext? _ctx;
  TradeInDraft _draft = TradeInDraft();
  VisitResult? _saved;
  int? _editingIndex; // null = adding a new club; set = editing existing

  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.text,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    _sigController.addListener(_onSignatureChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _sigController.removeListener(_onSignatureChanged);
    _sigController.dispose();
    super.dispose();
  }

  void _onSignatureChanged() {
    if (_draft.phase == 1 && _draft.editing == null && mounted) {
      setState(() {});
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ctx = await ProfileService.load();
      final draft = await DraftStore.load() ?? TradeInDraft();
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        _draft = draft;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your store profile. $e';
        _loading = false;
      });
    }
  }

  void _persist() => DraftStore.save(_draft);

  void _onChanged() {
    setState(() {});
    _persist();
  }

  double get _payout => _ctx?.payoutRate ?? 1.0;
  double _offer(DraftItem i) => (i.pgaValue ?? 0) * _payout;
  double get _visitTotal =>
      _draft.items.fold<double>(0, (s, i) => s + _offer(i));

  // --- visit list actions ---
  void _startAdd() {
    setState(() {
      _draft.editing = DraftItem();
      _draft.editStep = 0;
      _editingIndex = null;
    });
    _persist();
  }

  void _editExisting(int index) {
    setState(() {
      _draft.editing = _draft.items[index].copy();
      _draft.editStep = 0;
      _editingIndex = index;
    });
    _persist();
  }

  void _deleteItem(int index) {
    final removed = _draft.items.removeAt(index);
    for (final p in removed.photoPaths) {
      PhotoService.deleteFile(p);
    }
    _onChanged();
  }

  void _commitEditingItem() {
    final item = _draft.editing;
    if (item == null) return;
    setState(() {
      if (_editingIndex == null) {
        _draft.items.add(item);
      } else {
        _draft.items[_editingIndex!] = item;
      }
      _draft.editing = null;
      _editingIndex = null;
    });
    _persist();
  }

  void _cancelEditing() {
    final editing = _draft.editing;
    if (editing != null) {
      // Discard photos taken for this in-progress club that aren't already
      // part of the saved (original) item.
      final keep = _editingIndex == null
          ? const <String>[]
          : _draft.items[_editingIndex!].photoPaths;
      for (final p in editing.photoPaths) {
        if (!keep.contains(p)) PhotoService.deleteFile(p);
      }
    }
    setState(() {
      _draft.editing = null;
      _editingIndex = null;
    });
    _persist();
  }

  // --- sub-flow validation ---
  bool get _canAdvanceSub {
    final item = _draft.editing;
    if (item == null) return false;
    switch (_draft.editStep) {
      case 0:
        final basics = item.category != null &&
            (item.brand?.trim().isNotEmpty ?? false) &&
            (item.model?.trim().isNotEmpty ?? false);
        final specsOk = specsFor(item.category)
            .where((f) => f.required)
            .every((f) => (item.specs[f.key]?.trim().isNotEmpty ?? false));
        return basics && specsOk;
      case 1:
        return item.condition != null;
      case 2:
        return (item.pgaValue ?? 0) > 0;
      case 3:
        return item.photoPaths.length >= 2;
      default:
        return false;
    }
  }

  List<String> get _missingSub {
    final item = _draft.editing;
    if (item == null) return const [];
    switch (_draft.editStep) {
      case 0:
        final missing = <String>[];
        if (item.category == null) missing.add('Category');
        if (!(item.brand?.trim().isNotEmpty ?? false)) missing.add('Brand');
        if (!(item.model?.trim().isNotEmpty ?? false)) missing.add('Model');
        for (final f in specsFor(item.category).where((f) => f.required)) {
          if (!(item.specs[f.key]?.trim().isNotEmpty ?? false)) {
            missing.add(f.label);
          }
        }
        return missing;
      case 1:
        return item.condition == null ? ['Condition'] : const [];
      case 2:
        return (item.pgaValue ?? 0) > 0 ? const [] : ['PGA value'];
      case 3:
        return item.photoPaths.length >= 2 ? const [] : ['2 photos minimum'];
      default:
        return const [];
    }
  }

  void _subNext() {
    if (!_canAdvanceSub) return;
    if (_draft.editStep < 3) {
      setState(() => _draft.editStep++);
      _persist();
    } else {
      _commitEditingItem();
    }
  }

  void _subBack() {
    if (_draft.editStep == 0) {
      _cancelEditing();
    } else {
      setState(() => _draft.editStep--);
      _persist();
    }
  }

  // --- acceptance ---
  bool get _canConfirm =>
      _draft.customerAccepts &&
      _sigController.isNotEmpty &&
      _draft.items.isNotEmpty;

  Future<void> _confirm() async {
    final ctx = _ctx;
    if (ctx == null || !_canConfirm || _submitting) return;
    setState(() => _submitting = true);
    try {
      final signaturePng = await _sigController.toPngBytes();
      final result = await IntakeService.submitVisit(
        items: _draft.items,
        ctx: ctx,
        signaturePng: signaturePng,
      );
      for (final p in _draft.allPhotoPaths) {
        PhotoService.deleteFile(p);
      }
      await DraftStore.clear();
      if (!mounted) return;
      setState(() {
        _saved = result;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not save the visit. $e')));
    }
  }

  void _reset() {
    _sigController.clear();
    setState(() {
      _draft = TradeInDraft();
      _saved = null;
      _editingIndex = null;
    });
    DraftStore.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Trade-In')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _bootstrap, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    if (_saved != null) {
      return ConfirmationView(result: _saved!, onNew: _reset);
    }
    if (_draft.editing != null) return _buildSubFlow();
    if (_draft.phase == 1) return _buildAcceptance();
    return _buildVisitList();
  }

  // ---- Visit list (phase 0) ----
  Widget _buildVisitList() {
    final items = _draft.items;
    return Scaffold(
      appBar: const AppHeader(title: 'New Trade-In'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (items.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} club${items.length == 1 ? '' : 's'} in visit',
                      style: GoogleFonts.dmSans(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatMoney(_visitTotal),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: _HowItWorks(),
              )
            else
              for (var i = 0; i < items.length; i++)
                _VisitItemCard(
                  item: items[i],
                  offer: _offer(items[i]),
                  onEdit: () => _editExisting(i),
                  onDelete: () => _deleteItem(i),
                ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _startAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add club'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: items.isEmpty
                    ? null
                    : () {
                        setState(() => _draft.phase = 1);
                        _persist();
                      },
                child: const Text('Review & accept'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Per-club sub-flow ----
  Widget _buildSubFlow() {
    final item = _draft.editing!;
    final step = _draft.editStep;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingIndex == null ? 'Add club' : 'Edit club'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepProgress(step: step, total: 4),
                const SizedBox(height: 8),
                Text(
                  '${_subStepTitles[step]}  ·  ${step + 1}/4',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildSubStep(item, step)),
      bottomNavigationBar: _NavBar(
        backLabel: step == 0 ? 'Cancel' : 'Back',
        nextLabel: step == 3 ? 'Add to visit' : 'Next',
        canAdvance: _canAdvanceSub,
        submitting: false,
        hint: _canAdvanceSub
            ? null
            : 'Still needed: ${_missingSub.join('  ·  ')}',
        onBack: _subBack,
        onNext: _subNext,
      ),
    );
  }

  Widget _buildSubStep(DraftItem item, int step) {
    switch (step) {
      case 0:
        return StepItemDetails(draft: item, onChanged: _onChanged);
      case 1:
        return StepCondition(draft: item, onChanged: _onChanged);
      case 2:
        return StepValue(
            draft: item, payoutRate: _payout, onChanged: _onChanged);
      case 3:
        return StepPhotos(draft: item, onChanged: _onChanged);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- Acceptance (phase 1) ----
  Widget _buildAcceptance() {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & accept')),
      body: SafeArea(
        top: false,
        child: StepAcceptance(
          items: _draft.items,
          payoutRate: _payout,
          sigController: _sigController,
          customerAccepts: _draft.customerAccepts,
          onToggleAccept: () {
            _draft.customerAccepts = !_draft.customerAccepts;
            _onChanged();
          },
        ),
      ),
      bottomNavigationBar: _NavBar(
        backLabel: 'Back',
        nextLabel: 'Confirm & Save',
        canAdvance: _canConfirm,
        submitting: _submitting,
        hint: _canConfirm
            ? null
            : 'Still needed: ${[
                if (!_draft.customerAccepts) 'Acceptance',
                if (_sigController.isEmpty) 'Signature',
              ].join('  ·  ')}',
        onBack: () {
          setState(() => _draft.phase = 0);
          _persist();
        },
        onNext: _confirm,
      ),
    );
  }
}

class _VisitItemCard extends StatelessWidget {
  const _VisitItemCard({
    required this.item,
    required this.offer,
    required this.onEdit,
    required this.onDelete,
  });

  final DraftItem item;
  final double offer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      categoryFor(item.category)?.label,
      conditionFor(item.condition)?.label,
    ].whereType<String>().join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isEmpty ? 'Untitled club' : item.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.isEmpty ? '—' : subtitle,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatMoney(offer),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = <String>[
    'Details',
    'Condition',
    'Value',
    'Photos',
    'Accept',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('How it works'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        height: 26,
                        width: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF07230A),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _steps[i],
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bolt, color: AppColors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Look up each club’s value in Check Value first, and have the '
                'clubs ready to photograph.',
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i <= step;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: done ? AppColors.accent : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.backLabel,
    required this.nextLabel,
    required this.canAdvance,
    required this.submitting,
    required this.hint,
    required this.onBack,
    required this.onNext,
  });

  final String backLabel;
  final String nextLabel;
  final bool canAdvance;
  final bool submitting;
  final String? hint;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hint!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: submitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(backLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: (canAdvance && !submitting) ? onNext : null,
                  child: submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.text,
                          ),
                        )
                      : Text(nextLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
