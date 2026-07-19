import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/trade_in_draft.dart';
import '../../../services/photo_service.dart';
import '../../../theme/app_theme.dart';

/// Step 4 — camera capture, min 2 (clubface + full club), max 6.
class StepPhotos extends StatefulWidget {
  const StepPhotos({super.key, required this.draft, required this.onChanged});

  final DraftItem draft;
  final VoidCallback onChanged;

  @override
  State<StepPhotos> createState() => _StepPhotosState();
}

class _StepPhotosState extends State<StepPhotos> {
  static const int _max = 6;
  bool _busy = false;

  Future<void> _add(ImageSource source) async {
    if (_busy || widget.draft.photoPaths.length >= _max) return;
    setState(() => _busy = true);
    try {
      final path = await PhotoService.capture(source: source);
      if (path != null) {
        widget.draft.photoPaths.add(path);
        widget.onChanged();
      }
    } catch (e) {
      if (!mounted) return;
      final usingCamera = source == ImageSource.camera;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              usingCamera
                  ? 'Camera unavailable (the Simulator has no camera). '
                      'Use "Choose from library" to test.'
                  : 'Could not add photo. $e',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int index) {
    final path = widget.draft.photoPaths.removeAt(index);
    PhotoService.deleteFile(path);
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.draft.photoPaths;
    final count = photos.length;
    final enough = count >= 2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          children: [
            Icon(
              enough ? Icons.check_circle : Icons.info_outline,
              color: enough ? AppColors.accent : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Take at least 2 photos — clubface and full club. '
                '(Up to 6.)  $count/$_max added.',
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (var i = 0; i < photos.length; i++)
              _Thumb(path: photos[i], index: i, onRemove: () => _remove(i)),
            if (count < _max) _AddTile(busy: _busy, onTap: () => _add(ImageSource.camera)),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _busy || count >= _max
              ? null
              : () => _add(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from library (for Simulator testing)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: AppColors.textMuted,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.path,
    required this.index,
    required this.onRemove,
  });

  final String path;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 6,
          child: Text(
            index == 0 ? 'Clubface' : (index == 1 ? 'Full club' : '#${index + 1}'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 3, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: busy ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_camera, color: AppColors.accent, size: 28),
                      SizedBox(height: 6),
                      Text(
                        'Take photo',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
