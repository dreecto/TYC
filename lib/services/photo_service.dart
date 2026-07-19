import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Captures a photo (camera by default) and returns the path to a compressed
/// jpg stored in the app documents dir. Returns null if the user cancels.
class PhotoService {
  PhotoService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> capture({
    ImageSource source = ImageSource.camera,
  }) async {
    final XFile? shot = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (shot == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'trade_in_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }
    final target =
        p.join(photosDir.path, '${DateTime.now().microsecondsSinceEpoch}.jpg');

    // Compress to a sensible upload size.
    final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      shot.path,
      quality: 70,
      minWidth: 1400,
      minHeight: 1400,
    );

    final file = File(target);
    await file.writeAsBytes(compressed ?? await shot.readAsBytes());
    return file.path;
  }

  /// Best-effort deletion of a compressed photo file (e.g. when removed in UI).
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // ignore — cleanup only
    }
  }
}
