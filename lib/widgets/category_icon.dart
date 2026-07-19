import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import 'club_glyph.dart';

/// Category value -> SVG asset basename in assets/club_icons/.
/// "woods" covers both fairway woods and hybrids; "other" has no asset and
/// uses the built-in drawn glyph.
const Map<String, String> _svgForCategory = <String, String>{
  'driver': 'driver',
  'fairway': 'woods',
  'hybrid': 'woods',
  'iron_set': 'iron_set',
  'wedge': 'wedge',
  'putter': 'putter',
};

/// The intake tile icon for a club category: the provided SVG when it exists,
/// otherwise the drawn [ClubGlyph] fallback (so a missing file never breaks the
/// screen). Monochrome SVGs are tinted to [color].
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    required this.color,
    this.size = 32,
  });

  final String category;
  final Color color;
  final double size;

  static final Map<String, bool> _existsCache = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final name = _svgForCategory[category];
    if (name == null) return _glyph();

    final path = 'assets/club_icons/$name.svg';
    final cached = _existsCache[path];
    if (cached == false) return _glyph();
    if (cached == true) return _svg(path);

    return FutureBuilder<bool>(
      future: _check(path),
      builder: (context, snap) {
        if (snap.data == true) return _svg(path);
        if (snap.data == false) return _glyph();
        return _glyph(); // brief fallback while checking
      },
    );
  }

  Widget _glyph() =>
      ClubGlyph(category: category, color: color, size: size);

  Widget _svg(String path) => SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => _glyph(),
      );

  static Future<bool> _check(String path) async {
    try {
      await rootBundle.load(path);
      _existsCache[path] = true;
      return true;
    } catch (_) {
      _existsCache[path] = false;
      return false;
    }
  }
}
