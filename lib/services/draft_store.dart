import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trade_in_draft.dart';

/// Persists a single in-progress [TradeInDraft] to local storage.
class DraftStore {
  DraftStore._();

  static const _key = 'trade_in_draft_v1';

  static Future<void> save(TradeInDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    if (draft.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, draft.encode());
    }
  }

  static Future<TradeInDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_key);
    if (source == null) return null;
    try {
      final draft = TradeInDraft.decode(source);
      // Drop any photo paths whose files no longer exist on disk.
      final all = <DraftItem>[
        ...draft.items,
        if (draft.editing != null) draft.editing!,
      ];
      for (final item in all) {
        item.photoPaths.removeWhere((path) => !File(path).existsSync());
      }
      return draft;
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
