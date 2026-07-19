import 'package:flutter/material.dart';

/// A cohesive, monoline set of golf-club glyphs drawn per category, so each
/// intake tile reflects the actual item type (driver vs iron vs putter …)
/// instead of a mismatched stock icon.
///
/// Drawn in a 24×24 space and scaled to [size]. Side-view silhouettes with a
/// shaft, distinguished by head shape.
class ClubGlyph extends StatelessWidget {
  const ClubGlyph({
    super.key,
    required this.category,
    required this.color,
    this.size = 30,
  });

  final String category;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ClubPainter(category: category, color: color),
    );
  }
}

class _ClubPainter extends CustomPainter {
  _ClubPainter({required this.category, required this.color});

  final String category;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s, s);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void line(Offset a, Offset b) => canvas.drawLine(a, b, stroke);
    void shaft(Offset hosel) => line(hosel, const Offset(18.5, 3.5));

    switch (category) {
      case 'driver':
        canvas.drawCircle(const Offset(7, 16.5), 4.4, stroke);
        shaft(const Offset(10, 13.4));
        break;
      case 'fairway':
        canvas.drawCircle(const Offset(7, 17.2), 3.5, stroke);
        shaft(const Offset(9.5, 14.8));
        break;
      case 'hybrid':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 14, 8.2, 5.4),
            const Radius.circular(2.6),
          ),
          stroke,
        );
        shaft(const Offset(10.6, 14.6));
        break;
      case 'iron_set':
        // A fan of three irons — a set.
        const base = Offset(6.6, 20.6);
        line(base, const Offset(3.2, 8));
        line(base, const Offset(6.6, 7));
        line(base, const Offset(10.0, 8));
        break;
      case 'wedge':
        final blade = Path()
          ..moveTo(4, 20)
          ..lineTo(9, 19)
          ..lineTo(11, 12.4)
          ..lineTo(6, 12.9)
          ..close();
        canvas.drawPath(blade, stroke);
        line(const Offset(5.6, 15.2), const Offset(9.6, 14.5)); // grooves
        line(const Offset(5.9, 17.1), const Offset(9.1, 16.5));
        shaft(const Offset(9.6, 13.0));
        break;
      case 'putter':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(2.5, 18, 11, 3),
            const Radius.circular(1.5),
          ),
          stroke,
        );
        line(const Offset(8, 18), const Offset(8, 15.4)); // alignment neck
        shaft(const Offset(8, 15.4));
        break;
      default: // 'other' — a golf ball
        canvas.drawCircle(const Offset(12, 12), 5.4, stroke);
        for (final d in const [
          Offset(10, 10.4),
          Offset(13.2, 10),
          Offset(11.4, 13.2),
          Offset(14, 13.4),
        ]) {
          canvas.drawCircle(d, 0.75, fill);
        }
    }
  }

  @override
  bool shouldRepaint(_ClubPainter old) =>
      old.category != category || old.color != color;
}
