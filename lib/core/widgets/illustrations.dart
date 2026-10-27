import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum IllustrationKind { emptySearch, noTrips, offline, error, success }

/// Vector spot illustrations built on the "rail + station" motif.
/// All geometry is relative to the canvas so they scale cleanly.
class AppIllustration extends StatelessWidget {
  const AppIllustration({
    super.key,
    required this.kind,
    this.size = _defaultSize,
  });

  final IllustrationKind kind;
  final double size;

  static const _defaultSize = AppSpacing.xxxl * 3;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final accent = switch (kind) {
      IllustrationKind.error => scheme.error,
      IllustrationKind.offline => scheme.onSurfaceVariant,
      IllustrationKind.success => app.success,
      _ => scheme.primary,
    };
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SpotPainter(
          kind: kind,
          rail: app.metroLine,
          accent: accent,
          backdrop: scheme.primaryContainer,
          surface: scheme.surface,
          warm: app.warning,
        ),
      ),
    );
  }
}

class _SpotPainter extends CustomPainter {
  const _SpotPainter({
    required this.kind,
    required this.rail,
    required this.accent,
    required this.backdrop,
    required this.surface,
    required this.warm,
  });

  final IllustrationKind kind;
  final Color rail;
  final Color accent;
  final Color backdrop;
  final Color surface;
  final Color warm;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w / 2);
    final stroke = w * .03;

    // Soft backdrop disc.
    canvas.drawCircle(c, w * .46, Paint()..color = backdrop);

    // The rail across the disc with three stations.
    final railY = w * .66;
    final railPaint = Paint()
      ..color = rail
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (kind == IllustrationKind.offline) {
      canvas.drawLine(
        Offset(w * .14, railY),
        Offset(w * .42, railY),
        railPaint,
      );
      canvas.drawLine(
        Offset(w * .58, railY),
        Offset(w * .86, railY),
        railPaint,
      );
    } else {
      canvas.drawLine(
        Offset(w * .14, railY),
        Offset(w * .86, railY),
        railPaint,
      );
    }
    for (final x in [.22, .5, .78]) {
      if (kind == IllustrationKind.offline && x == .5) continue;
      final p = Offset(w * x, railY);
      canvas.drawCircle(p, w * .05, Paint()..color = surface);
      canvas.drawCircle(
        p,
        w * .05,
        Paint()
          ..color = rail
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * .8,
      );
    }

    final accentStroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final accentFill = Paint()..color = accent;

    switch (kind) {
      case IllustrationKind.emptySearch:
        final lens = Offset(w * .46, w * .38);
        canvas.drawCircle(lens, w * .13, Paint()..color = surface);
        canvas.drawCircle(lens, w * .13, accentStroke);
        canvas.drawLine(
          lens + Offset(w * .09, w * .09),
          lens + Offset(w * .19, w * .19),
          accentStroke..strokeWidth = stroke * 1.4,
        );
      case IllustrationKind.noTrips:
        // Map pin above the middle station + dashed path to it.
        final tip = Offset(w * .5, railY - w * .08);
        final head = Offset(w * .5, w * .3);
        final pin = Path()
          ..moveTo(tip.dx, tip.dy)
          ..quadraticBezierTo(w * .34, w * .4, w * .36, head.dy)
          ..arcToPoint(
            Offset(w * .64, head.dy),
            radius: Radius.circular(w * .14),
          )
          ..quadraticBezierTo(w * .66, w * .4, tip.dx, tip.dy)
          ..close();
        canvas.drawPath(pin, accentFill);
        canvas.drawCircle(head, w * .05, Paint()..color = surface);
        final dash = Paint()
          ..color = warm
          ..strokeWidth = stroke * .7
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final x = w * (.2 + i * .05);
          canvas.drawLine(
            Offset(x, w * .5),
            Offset(x + w * .025, w * .48),
            dash,
          );
        }
      case IllustrationKind.offline:
        // Signal arcs with a slash.
        final o = Offset(w * .5, w * .44);
        for (final r in [.08, .15, .22]) {
          canvas.drawArc(
            Rect.fromCircle(center: o, radius: w * r),
            math.pi * 1.2,
            math.pi * .6,
            false,
            accentStroke,
          );
        }
        canvas.drawLine(
          Offset(w * .3, w * .2),
          Offset(w * .7, w * .5),
          accentStroke..color = warm,
        );
      case IllustrationKind.error:
        final tri = Path()
          ..moveTo(w * .5, w * .18)
          ..lineTo(w * .7, w * .52)
          ..lineTo(w * .3, w * .52)
          ..close();
        canvas.drawPath(tri, Paint()..color = surface);
        canvas.drawPath(tri, accentStroke..strokeJoin = StrokeJoin.round);
        canvas.drawLine(
          Offset(w * .5, w * .3),
          Offset(w * .5, w * .41),
          accentStroke,
        );
        canvas.drawCircle(Offset(w * .5, w * .46), stroke * .7, accentFill);
      case IllustrationKind.success:
        final o = Offset(w * .5, w * .38);
        canvas.drawCircle(o, w * .15, accentFill);
        final tick = Path()
          ..moveTo(w * .43, w * .38)
          ..lineTo(w * .48, w * .43)
          ..lineTo(w * .58, w * .33);
        canvas.drawPath(
          tick,
          Paint()
            ..color = surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
    }
  }

  @override
  bool shouldRepaint(_SpotPainter old) =>
      old.kind != kind ||
      old.rail != rail ||
      old.accent != accent ||
      old.backdrop != backdrop;
}

/// Decorative backdrop for the Home hero: elevated track, a Line 1 train and
/// a low skyline. Painted in [color] with low alpha over a navy gradient.
class MetroHeroArt extends StatelessWidget {
  const MetroHeroArt({super.key, required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _HeroPainter(color: color, accent: accent),
      size: Size.infinite,
    ),
  );
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = h * .78;

    // Sun.
    canvas.drawCircle(
      Offset(w * .82, h * .26),
      h * .12,
      Paint()..color = accent.withValues(alpha: .9),
    );

    // Skyline blocks (fractions of width/height).
    final skyline = Paint()..color = color.withValues(alpha: .10);
    const blocks = [
      [.52, .40, .06],
      [.59, .28, .05],
      [.65, .46, .07],
      [.73, .34, .05],
      [.79, .52, .06],
      [.86, .30, .05],
      [.92, .44, .08],
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * b[0], h * b[1], w * b[2], base - h * b[1]),
          Radius.circular(w * .008),
        ),
        skyline,
      );
    }

    // Elevated track with pillars.
    final track = Paint()
      ..color = color.withValues(alpha: .35)
      ..strokeWidth = h * .025;
    canvas.drawLine(Offset(w * .4, base), Offset(w, base), track);
    final pillar = Paint()
      ..color = color.withValues(alpha: .18)
      ..strokeWidth = w * .012;
    for (var x = .46; x < 1; x += .12) {
      canvas.drawLine(Offset(w * x, base), Offset(w * x, h), pillar);
    }

    // Train: three cars with windows.
    final carH = h * .13;
    final carW = w * .13;
    final top = base - carH - h * .02;
    final body = Paint()..color = color.withValues(alpha: .92);
    final window = Paint()..color = accent.withValues(alpha: .25);
    for (var i = 0; i < 3; i++) {
      final left = w * .56 + i * (carW + w * .01);
      final car = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, carW, carH),
        topLeft: Radius.circular(i == 0 ? carH * .6 : carH * .2),
        topRight: Radius.circular(carH * .2),
        bottomLeft: Radius.circular(carH * .15),
        bottomRight: Radius.circular(carH * .15),
      );
      canvas.drawRRect(car, body);
      for (var k = 0; k < 3; k++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              left + carW * (.12 + k * .28),
              top + carH * .22,
              carW * .2,
              carH * .32,
            ),
            Radius.circular(carH * .06),
          ),
          window,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.color != color || old.accent != accent;
}
