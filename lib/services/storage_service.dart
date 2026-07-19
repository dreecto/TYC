import 'auth_service.dart';

/// Signed-URL access to the private item-photos bucket. Paths follow
/// {partner_id}/{item_id}/{n}.jpg with a sibling signature.png.
class StorageService {
  StorageService._();

  static const _bucket = 'item-photos';
  static const _ttl = 3600; // 1 hour

  static dynamic get _storage => AuthService.client.storage.from(_bucket);

  /// Signed URL for the first photo (thumbnail), or null if none.
  static Future<String?> firstPhotoUrl(String partnerId, String itemId) async {
    try {
      return await _storage.createSignedUrl('$partnerId/$itemId/1.jpg', _ttl);
    } catch (_) {
      return null;
    }
  }

  /// Signed URLs for every photo in the item folder, in numeric order.
  static Future<List<String>> allPhotoUrls(
      String partnerId, String itemId) async {
    try {
      final List<dynamic> objects =
          await _storage.list(path: '$partnerId/$itemId');
      final jpgs = objects
          .where((o) => (o.name as String).toLowerCase().endsWith('.jpg'))
          .toList()
        ..sort((a, b) => _leadingInt(a.name).compareTo(_leadingInt(b.name)));

      final urls = <String>[];
      for (final o in jpgs) {
        urls.add(await _storage.createSignedUrl(
          '$partnerId/$itemId/${o.name}',
          _ttl,
        ));
      }
      return urls;
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> signatureUrl(String partnerId, String itemId) async {
    try {
      return await _storage.createSignedUrl(
        '$partnerId/$itemId/signature.png',
        _ttl,
      );
    } catch (_) {
      return null;
    }
  }

  static int _leadingInt(String name) {
    final match = RegExp(r'^(\d+)').firstMatch(name);
    return match == null ? 1 << 30 : int.parse(match.group(1)!);
  }
}
