import 'package:flutter/material.dart';

class WaterBottle extends StatelessWidget {
  /// Color of the water
  final Color waterColor;

  /// Color of the bottle
  final Color bottleColor;

  /// Color of the bottle cap
  final Color capColor;

  /// Water level from 0.0 to 1.0
  final double waterLevel;

  /// Create a regular bottle, you can customize it's part with
  /// [waterColor], [bottleColor], [capColor].
  WaterBottle({
    Key? key,
    this.waterColor = Colors.blue,
    this.bottleColor = Colors.blue,
    this.capColor = Colors.blueGrey,
    this.waterLevel = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: CustomPaint(
        painter: WaterBottlePainter(
          waterLevel: waterLevel,
          waterColor: waterColor,
          bottleColor: bottleColor,
          capColor: capColor,
        ),
      ),
    );
  }
}

class WaterBottlePainter extends CustomPainter {
  /// Water level, 0 = no water, 1 = full water
  final double waterLevel;

  /// Water color
  final Color waterColor;

  /// Bottle color
  final Color bottleColor;

  /// Bottle cap color
  final Color capColor;

  WaterBottlePainter({
    required this.waterLevel,
    required this.waterColor,
    required this.bottleColor,
    required this.capColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bottle
    {
      final paint = Paint();
      paint.color = bottleColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      paintEmptyBottle(canvas, size, paint);
    }

    // Water
    {
      final paint = Paint();
      paint.color = waterColor;
      paint.style = PaintingStyle.fill;
      paintStaticWater(canvas, size, paint);
    }

    // Glossy-Effect
    {
      final paint = Paint();
      paint.style = PaintingStyle.fill;
      paintGlossyOverlay(canvas, size, paint);
    }

    // Cap
    {
      final paint = Paint();
      paint.style = PaintingStyle.fill;
      paint.color = capColor;
      paintCap(canvas, size, paint);
    }
  }

  void paintEmptyBottle(Canvas canvas, Size size, Paint paint) {
    final neckTop = size.width * 0.1;
    final neckBottom = size.height;
    final neckRingOuter = 0.0;
    final neckRingOuterR = size.width - neckRingOuter;
    final neckRingInner = size.width * 0.1;
    final neckRingInnerR = size.width - neckRingInner;
    final path = Path();
    path.moveTo(neckRingOuter, neckTop);
    path.lineTo(neckRingInner, neckTop);
    path.lineTo(neckRingInner, neckBottom);
    path.lineTo(neckRingInnerR, neckBottom);
    path.lineTo(neckRingInnerR, neckTop);
    path.lineTo(neckRingOuterR, neckTop);
    canvas.drawPath(path, paint);
  }

  void paintStaticWater(Canvas canvas, Size size, Paint paint) {
    if (waterLevel <= 0) return;

    final neckRingInner = size.width * 0.1;
    final neckRingInnerR = size.width - neckRingInner;

    final waterHeight = (size.height - 5) * waterLevel;
    final waterTop = size.height - 5 - waterHeight;

    canvas.drawRect(
      Rect.fromLTRB(
        neckRingInner + 5,
        waterTop,
        neckRingInnerR - 5,
        size.height - 5,
      ),
      paint,
    );
  }

  void paintGlossyOverlay(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withAlpha(30);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width * 0.3, size.height), paint);

    paint.color = Colors.white.withAlpha(60);
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.85, 0, size.width * 0.9, size.height),
      paint,
    );
  }

  void paintCap(Canvas canvas, Size size, Paint paint) {
    final capTop = 0.0;
    final capBottom = size.width * 0.2;
    final capMid = (capBottom - capTop) / 2;
    final capL = size.width * 0.08 + 5;
    final capR = size.width - capL;
    final neckRingInner = size.width * 0.1 + 5;
    final neckRingInnerR = size.width - neckRingInner;
    final path = Path();
    path.moveTo(capL, capTop);
    path.lineTo(neckRingInner, capMid);
    path.lineTo(neckRingInner, capBottom);
    path.lineTo(neckRingInnerR, capBottom);
    path.lineTo(neckRingInnerR, capMid);
    path.lineTo(capR, capTop);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaterBottlePainter oldDelegate) {
    return oldDelegate.waterLevel != waterLevel ||
        oldDelegate.waterColor != waterColor ||
        oldDelegate.bottleColor != bottleColor ||
        oldDelegate.capColor != capColor;
  }
}
