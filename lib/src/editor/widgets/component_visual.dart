import 'package:flutter/material.dart';

import '../../model/ui_node.dart';

class ComponentVisual extends StatelessWidget {
  const ComponentVisual({
    required this.type,
    this.properties = const {},
    this.compact = false,
    super.key,
  });

  final String type;
  final Map<String, Object?> properties;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ComponentPainter(
        type: type,
        properties: properties,
        compact: compact,
        foreground: scheme.onSurface,
        surface: scheme.surfaceContainerLow,
        primary: scheme.primary,
        secondary: scheme.secondary,
        outline: scheme.outline,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class NodeVisual extends StatelessWidget {
  const NodeVisual({
    required this.node,
    this.compact = false,
    super.key,
  });

  final UiNode node;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: ComponentVisual(
              type: node.type,
              properties: node.properties,
              compact: compact,
            ),
          ),
          if (!compact)
            for (final child in node.children)
              if (child.visible)
                Positioned(
                  left: child.frame.x,
                  top: child.frame.y,
                  width: child.frame.width,
                  height: child.frame.height,
                  child: Transform.rotate(
                    angle: child.rotation * 0.017453292519943295,
                    child: IgnorePointer(
                      child: NodeVisual(node: child),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ComponentPainter extends CustomPainter {
  const _ComponentPainter({
    required this.type,
    required this.properties,
    required this.compact,
    required this.foreground,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.outline,
  });

  final String type;
  final Map<String, Object?> properties;
  final bool compact;
  final Color foreground;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (compact ? 1.4 : 1.2).clamp(1.0, 2.0).toDouble()
      ..color = outline;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = surface;
    final primaryFill = Paint()
      ..style = PaintingStyle.fill
      ..color = primary.withValues(alpha: .16);
    final strong = Paint()
      ..style = PaintingStyle.fill
      ..color = primary;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = foreground.withValues(alpha: .70);

    Rect inset(double amount) => Rect.fromLTWH(
          amount,
          amount,
          (w - amount * 2).clamp(0.0, w).toDouble(),
          (h - amount * 2).clamp(0.0, h).toDouble(),
        );

    void roundedBox({
      double margin = 4,
      double radius = 8,
      Paint? paint,
    }) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          inset(margin),
          Radius.circular(radius),
        ),
        paint ?? fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          inset(margin),
          Radius.circular(radius),
        ),
        stroke,
      );
    }

    void horizontalLine(double y, double left, double right) {
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        line,
      );
    }

    switch (type) {
      case 'text':
        _drawTextContent(canvas, size, foreground);
        return;
      case 'note':
        _drawNote(canvas, size);
        return;
      case 'image':
        roundedBox();
        final iconPainter = TextPainter(
          text: TextSpan(
            text: '▱',
            style: TextStyle(
              color: foreground.withValues(alpha: .75),
              fontSize: (h * .55).clamp(18.0, 42.0).toDouble(),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        iconPainter.paint(
          canvas,
          Offset(
            (w - iconPainter.width) / 2,
            (h - iconPainter.height) / 2,
          ),
        );
        return;
      case 'container':
        roundedBox(radius: 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .12, h * .16, w * .76, h * .68),
            const Radius.circular(4),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = outline.withValues(alpha: .55),
        );
        return;
      case 'row':
        roundedBox(radius: 5);
        _drawLayoutBlocks(canvas, size, horizontal: true);
        return;
      case 'column':
        roundedBox(radius: 5);
        _drawLayoutBlocks(canvas, size, horizontal: false);
        return;
      case 'stack':
        roundedBox(radius: 5);
        _drawStackBlocks(canvas, size);
        return;
      case 'textField':
        roundedBox(margin: 6, radius: 5);
        horizontalLine(h * .52, w * .15, w * .72);
        return;
      case 'switch':
        final track = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w / 2, h / 2),
            width: w * .62,
            height: h * .46,
          ),
          Radius.circular(h),
        );
        canvas.drawRRect(track, primaryFill);
        canvas.drawRRect(track, stroke);
        canvas.drawCircle(
          Offset(w * .60, h / 2),
          h * .17,
          strong,
        );
        return;
      case 'slider':
        horizontalLine(h / 2, w * .12, w * .88);
        canvas.drawCircle(Offset(w * .58, h / 2), 6, strong);
        return;
      case 'filledButton':
      case 'button':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .08, h * .18, w * .84, h * .64),
            Radius.circular(h * .20),
          ),
          primaryFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .08, h * .18, w * .84, h * .64),
            Radius.circular(h * .20),
          ),
          stroke,
        );
        horizontalLine(h / 2, w * .36, w * .64);
        return;
      case 'appBar':
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), primaryFill);
        canvas.drawCircle(Offset(w * .10, h / 2), h * .12, stroke);
        horizontalLine(h / 2, w * .24, w * .60);
        canvas.drawCircle(Offset(w * .88, h / 2), h * .10, stroke);
        return;
      case 'bottomNavigation':
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);
        canvas.drawLine(Offset(0, 0), Offset(w, 0), stroke);
        for (final x in <double>[.22, .50, .78]) {
          canvas.drawCircle(Offset(w * x, h * .38), h * .11, stroke);
          horizontalLine(h * .70, w * x - w * .05, w * x + w * .05);
        }
        return;
      case 'navigationDrawer':
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);
        canvas.drawLine(Offset(w - 1, 0), Offset(w - 1, h), stroke);
        canvas.drawCircle(Offset(w * .18, h * .13), w * .08, primaryFill);
        for (var i = 0; i < 4; i++) {
          final y = h * (.30 + i * .14);
          canvas.drawCircle(Offset(w * .14, y), 4, stroke);
          horizontalLine(y, w * .26, w * .74);
        }
        return;
      case 'floatingActionButton':
        canvas.drawCircle(
          Offset(w / 2, h / 2),
          (w < h ? w : h) * .40,
          primaryFill,
        );
        canvas.drawCircle(
          Offset(w / 2, h / 2),
          (w < h ? w : h) * .40,
          stroke,
        );
        horizontalLine(h / 2, w * .34, w * .66);
        canvas.drawLine(
          Offset(w / 2, h * .34),
          Offset(w / 2, h * .66),
          line,
        );
        return;
      case 'bottomSheet':
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(0, h * .10, w, h * .90),
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
          ),
          fill,
        );
        horizontalLine(h * .18, w * .40, w * .60);
        for (var i = 0; i < 3; i++) {
          horizontalLine(
            h * (.38 + i * .18),
            w * .12,
            w * (.82 - i * .06),
          );
        }
        return;
      case 'menuBar':
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);
        for (var i = 0; i < 4; i++) {
          horizontalLine(h / 2, w * (.05 + i * .18), w * (.14 + i * .18));
        }
        return;
      case 'navigationRail':
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);
        for (var i = 0; i < 4; i++) {
          final y = h * (.18 + i * .18);
          canvas.drawCircle(Offset(w * .22, y), 5, stroke);
          horizontalLine(y, w * .38, w * .78);
        }
        return;
      case 'splitView':
        roundedBox(radius: 3);
        canvas.drawLine(Offset(w * .34, 4), Offset(w * .34, h - 4), stroke);
        return;
      case 'contextMenu':
        roundedBox(radius: 5);
        for (var i = 0; i < 4; i++) {
          horizontalLine(
            h * (.22 + i * .19),
            w * .16,
            w * (.76 - i * .03),
          );
        }
        return;
      default:
        roundedBox();
        canvas.drawCircle(Offset(w / 2, h / 2), 5, strong);
    }
  }

  void _drawTextContent(Canvas canvas, Size size, Color color) {
    final value = properties['text']?.toString() ?? '';
    if (value.isEmpty || compact) {
      final paint = Paint()
        ..color = color.withValues(alpha: .72)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * .10, size.height * .40),
        Offset(size.width * .84, size.height * .40),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * .10, size.height * .63),
        Offset(size.width * .58, size.height * .63),
        paint,
      );
      return;
    }
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: (size.height * .42).clamp(10.0, 24.0).toDouble(),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: size.width * .90);
    painter.paint(
      canvas,
      Offset(size.width * .05, (size.height - painter.height) / 2),
    );
  }

  void _drawNote(Canvas canvas, Size size) {
    final noteFill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF2A8);
    final noteStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF8F7D35);

    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      noteFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      noteStroke,
    );

    final fold = Path()
      ..moveTo(size.width - 24, 3)
      ..lineTo(size.width - 3, 24)
      ..lineTo(size.width - 3, 3)
      ..close();
    canvas.drawPath(
      fold,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE6D276),
    );

    if (compact) {
      final p = Paint()
        ..color = const Color(0xFF746523)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = size.height * (.38 + i * .16);
        canvas.drawLine(
          Offset(size.width * .16, y),
          Offset(size.width * (.78 - i * .05), y),
          p,
        );
      }
      return;
    }

    final value = properties['text']?.toString() ?? '';
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: const Color(0xFF514716),
          fontSize: (size.height * .10).clamp(10.0, 18.0).toDouble(),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 6,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 24);
    painter.paint(canvas, const Offset(12, 14));
  }

  void _drawLayoutBlocks(
    Canvas canvas,
    Size size, {
    required bool horizontal,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = primary.withValues(alpha: .18);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: .72);

    for (var i = 0; i < 3; i++) {
      final rect = horizontal
          ? Rect.fromLTWH(
              size.width * (.10 + i * .29),
              size.height * .26,
              size.width * .22,
              size.height * .48,
            )
          : Rect.fromLTWH(
              size.width * .22,
              size.height * (.10 + i * .29),
              size.width * .56,
              size.height * .22,
            );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        border,
      );
    }
  }

  void _drawStackBlocks(Canvas canvas, Size size) {
    final fills = <Color>[
      primary.withValues(alpha: .12),
      secondary.withValues(alpha: .16),
      primary.withValues(alpha: .20),
    ];
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        size.width * (.16 + i * .10),
        size.height * (.14 + i * .10),
        size.width * .54,
        size.height * .50,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = fills[i],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = outline,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ComponentPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.properties != properties ||
      oldDelegate.compact != compact ||
      oldDelegate.foreground != foreground ||
      oldDelegate.surface != surface ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.outline != outline;
}
