import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/garden_engine.dart';

/// Calm, lightweight vector plant — shared five-stage rules across three
/// varieties. No images; a `Semantics` label in the widget carries the text
/// equivalent for screen readers.
class PlantIllustration extends StatelessWidget {
  final int variety; // 0..2
  final PlantStage stage;
  final int potStyle; // 0..2
  final double size;
  final bool mature; // completed plants render fully grown + a ring

  const PlantIllustration({
    super.key,
    required this.variety,
    required this.stage,
    this.potStyle = 0,
    this.size = 96,
    this.mature = false,
  });

  static Color foliage(int v) => switch (v) {
        0 => const Color(0xFF3E8E5A), // fern green
        1 => const Color(0xFF6B5B95), // lavender
        _ => const Color(0xFF5A8F7B), // succulent sage
      };
  static Color bloom(int v) => switch (v) {
        0 => const Color(0xFF8FBF6A),
        1 => const Color(0xFFB49AD6),
        _ => const Color(0xFFE7A6A0),
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlantPainter(
          variety: variety,
          stage: mature ? PlantStage.flowering : stage,
          potStyle: potStyle,
          mature: mature,
          growth: _growthFraction(context),
        ),
      ),
    );
  }

  // A stage→fill fraction so growth can animate smoothly after a new moment.
  double _growthFraction(BuildContext context) {
    if (mature) return 1;
    return switch (stage) {
      PlantStage.seed => 0.12,
      PlantStage.sprout => 0.35,
      PlantStage.leaves => 0.6,
      PlantStage.buds => 0.82,
      PlantStage.flowering => 1.0,
    };
  }
}

class _PlantPainter extends CustomPainter {
  final int variety;
  final PlantStage stage;
  final int potStyle;
  final bool mature;
  final double growth;
  const _PlantPainter({
    required this.variety,
    required this.stage,
    required this.potStyle,
    required this.mature,
    required this.growth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final potTop = h * 0.72;
    _paintPot(canvas, cx, potTop, w, h);

    if (stage == PlantStage.seed) {
      // a small seed resting in the soil
      canvas.drawCircle(Offset(cx, potTop - h * 0.02), w * 0.05,
          Paint()..color = PlantIllustration.foliage(variety));
      return;
    }

    final stemTop = h * (0.70 - 0.5 * growth);
    final stem = Paint()
      ..color = PlantIllustration.foliage(variety)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, potTop), Offset(cx, stemTop), stem);

    final leafPaint = Paint()..color = PlantIllustration.foliage(variety);
    final bloomPaint = Paint()..color = PlantIllustration.bloom(variety);

    // leaves grow with the stage
    final leafCount = switch (stage) {
      PlantStage.sprout => 1,
      PlantStage.leaves => 3,
      PlantStage.buds => 4,
      _ => 5,
    };
    for (var i = 0; i < leafCount; i++) {
      final t = (i + 1) / (leafCount + 1);
      final y = potTop - (potTop - stemTop) * t;
      final dir = i.isEven ? 1 : -1;
      _leaf(canvas, Offset(cx, y), dir, w * 0.14 * (0.6 + 0.4 * growth), leafPaint, variety);
    }

    if (stage == PlantStage.buds) {
      canvas.drawCircle(Offset(cx, stemTop), w * 0.05, bloomPaint);
    }
    if (stage == PlantStage.flowering) {
      _bloom(canvas, cx, stemTop, w, bloomPaint, variety);
    }
    if (mature) {
      canvas.drawCircle(
        Offset(cx, h * 0.5),
        w * 0.46,
        Paint()
          ..color = PlantIllustration.bloom(variety).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.02,
      );
    }
  }

  void _paintPot(Canvas canvas, double cx, double top, double w, double h) {
    final bottom = h * 0.95;
    final halfTop = w * 0.20;
    final halfBottom = w * (potStyle == 2 ? 0.12 : 0.15);
    final pot = Path()
      ..moveTo(cx - halfTop, top)
      ..lineTo(cx + halfTop, top)
      ..lineTo(cx + halfBottom, bottom)
      ..lineTo(cx - halfBottom, bottom)
      ..close();
    final scheme = potStyle == 0
        ? const Color(0xFFB07A5A)
        : potStyle == 1
            ? const Color(0xFF8A8F98)
            : const Color(0xFF6E6250);
    canvas.drawPath(pot, Paint()..color = scheme);
    // rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, top), width: halfTop * 2, height: w * 0.05),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Color.lerp(scheme, Colors.black, 0.18)!,
    );
  }

  void _leaf(Canvas canvas, Offset at, int dir, double len, Paint paint, int v) {
    final p = Path()
      ..moveTo(at.dx, at.dy)
      ..quadraticBezierTo(at.dx + dir * len, at.dy - len * 0.5,
          at.dx + dir * len * 1.2, at.dy - len * 0.1)
      ..quadraticBezierTo(at.dx + dir * len * 0.6, at.dy + len * 0.3,
          at.dx, at.dy);
    if (v == 0) {
      // fern: draw a slim frond instead of a broad leaf
      canvas.drawPath(p, paint..style = PaintingStyle.stroke..strokeWidth = len * 0.18);
      paint.style = PaintingStyle.fill;
    } else {
      canvas.drawPath(p, paint);
    }
  }

  void _bloom(Canvas canvas, double cx, double top, double w, Paint paint, int v) {
    if (v == 1) {
      // lavender: a vertical spike of small florets
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(Offset(cx, top + i * w * 0.03), w * 0.03, paint);
      }
      return;
    }
    if (v == 2) {
      // succulent: a rosette of petals
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawCircle(
            Offset(cx + math.cos(a) * w * 0.08, top + math.sin(a) * w * 0.08),
            w * 0.03, paint);
      }
      return;
    }
    // fern variety: a lighter frond tip cluster
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + (i - 2) * 0.35;
      canvas.drawCircle(
          Offset(cx + math.cos(a) * w * 0.1, top + math.sin(a) * w * 0.1),
          w * 0.025, paint);
    }
  }

  @override
  bool shouldRepaint(_PlantPainter old) =>
      old.variety != variety ||
      old.stage != stage ||
      old.potStyle != potStyle ||
      old.mature != mature ||
      old.growth != growth;
}
