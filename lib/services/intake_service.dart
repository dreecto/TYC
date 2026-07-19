import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trade_in_draft.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// One saved club within a visit — enough to render the confirmation screen.
class SavedIntake {
  final String id;
  final String title;
  final double offer;

  const SavedIntake({
    required this.id,
    required this.title,
    required this.offer,
  });
}

/// Result of saving a whole customer visit.
class VisitResult {
  final String visitId;
  final List<SavedIntake> items;
  final double total;

  const VisitResult({
    required this.visitId,
    required this.items,
    required this.total,
  });
}

class IntakeService {
  IntakeService._();

  static const _bucket = 'item-photos';

  /// Saves every club in the visit under a shared visit_id, with one shared
  /// signature and acceptance timestamp. Each row is inserted first, then its
  /// photos + the shared signature are uploaded to
  /// item-photos/{partner_id}/{item_id}/...
  static Future<VisitResult> submitVisit({
    required List<DraftItem> items,
    required PartnerContext ctx,
    required Uint8List? signaturePng,
  }) async {
    final client = AuthService.client;
    final userId = AuthService.currentUser!.id;
    final visitId = _uuidV4();
    final acceptedAt = DateTime.now().toUtc().toIso8601String();

    final saved = <SavedIntake>[];
    var total = 0.0;

    for (final item in items) {
      final offer = (item.pgaValue ?? 0) * ctx.payoutRate;
      total += offer;

      final inserted = await client
          .from('intake_items')
          .insert(<String, dynamic>{
            'partner_id': ctx.partnerId,
            'created_by': userId,
            'visit_id': visitId,
            'brand': item.brand,
            'model': item.model,
            'category': item.category,
            'specs': item.specs,
            'condition': item.condition,
            'pga_value': item.pgaValue,
            'offer_value': offer,
            'status': 'accepted',
            'customer_accepted_at': acceptedAt,
          })
          .select('id')
          .single();

      final itemId = inserted['id'] as String;
      final storage = client.storage.from(_bucket);
      final basePath = '${ctx.partnerId}/$itemId';

      for (var i = 0; i < item.photoPaths.length; i++) {
        final n = i + 1;
        final bytes = await File(item.photoPaths[i]).readAsBytes();
        await storage.uploadBinary(
          '$basePath/$n.jpg',
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      }

      if (signaturePng != null) {
        await storage.uploadBinary(
          '$basePath/signature.png',
          signaturePng,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );
      }

      saved.add(SavedIntake(
        id: itemId,
        title: item.title.isEmpty ? 'Untitled club' : item.title,
        offer: offer,
      ));
    }

    return VisitResult(visitId: visitId, items: saved, total: total);
  }

  /// RFC 4122 v4 UUID, generated client-side so a visit's rows share one id.
  static String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) {
      final b = StringBuffer();
      for (var i = start; i < end; i++) {
        b.write(bytes[i].toRadixString(16).padLeft(2, '0'));
      }
      return b.toString();
    }

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
