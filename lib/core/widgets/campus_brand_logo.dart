import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Accurate vector representation of the CampusFix brand mark as seen on
/// https://campusfixed.netlify.app/
///
/// Features the signature deep navy tile, dashed inner ring, white wrench tool,
/// and warm amber beacon dot.
class CampusBrandLogo extends StatelessWidget {
  const CampusBrandLogo({
    this.size = 32.0,
    this.showWordmark = false,
    this.wordmarkFontSize = 18.0,
    this.useVectorFallback = false,
    super.key,
  });

  final double size;
  final bool showWordmark;
  final double wordmarkFontSize;
  final bool useVectorFallback;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget logoIcon = SizedBox(
      width: size,
      height: size,
      child: useVectorFallback
          ? CustomPaint(painter: _CampusFixLogoPainter())
          : Image.asset(
              'assets/images/campusfix_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  CustomPaint(painter: _CampusFixLogoPainter()),
            ),
    );

    if (!showWordmark) {
      return logoIcon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        SizedBox(width: size * 0.3),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Campus',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: wordmarkFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              TextSpan(
                text: 'Fix',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: wordmarkFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.brandAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampusFixLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32.0;

    // 1. Navy Tile Background (#0E1728) with rounded corners (rx = 8)
    final bgPaint = Paint()
      ..color = AppColors.deepNavy
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(8.0 * scale),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Dashed Circle (cx: 16, cy: 16, r: 13, stroke: #243145)
    final dashPaint = Paint()
      ..color = AppColors.navyBorder
      ..strokeWidth = 1.0 * scale
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 13.0 * scale;
    const dashCount = 20;
    const sweepAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * 0.5,
        false,
        dashPaint,
      );
    }

    // 3. Wrench / Tool Vector Shape in White
    // SVG path normalized from 32x32:
    // M21.5 10.5 a4.2 4.2 0 0 0 -5.4 -.4 l-3 3 2.2 2.2 3-3 a4.2 4.2 0 0 0 3.2-1.8 z
    // M14.5 16 l-4.2 4.2 a1.4 1.4 0 0 0 2 2 l4.2-4.2 -2-2 z
    final toolPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.scale(scale, scale);

    final path = Path();
    // Head / Jaw of wrench
    path.moveTo(21.5, 10.5);
    path.arcToPoint(
      const Offset(16.1, 10.1),
      radius: const Radius.circular(4.2),
      clockwise: false,
    );
    path.lineTo(13.1, 13.1);
    path.lineTo(15.3, 15.3);
    path.lineTo(18.3, 12.3);
    path.arcToPoint(
      const Offset(21.5, 10.5),
      radius: const Radius.circular(4.2),
      clockwise: false,
    );
    path.close();

    // Handle of wrench
    path.moveTo(14.5, 16.0);
    path.lineTo(10.3, 20.2);
    path.arcToPoint(
      const Offset(12.3, 22.2),
      radius: const Radius.circular(1.4),
      clockwise: false,
    );
    path.lineTo(16.5, 18.0);
    path.lineTo(14.5, 16.0);
    path.close();

    canvas.drawPath(path, toolPaint);

    // 4. Amber Beacon Dot (cx: 21, cy: 11, r: 2.2, fill: #F59E0B)
    final amberPaint = Paint()
      ..color = AppColors.brandAmber
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(21.0, 11.0), 2.2, amberPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
