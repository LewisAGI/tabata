import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'icon_tip.dart';

Future<void> showRuler({
  required BuildContext context,
  required String title,
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _RulerSheet(
        title: title,
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      );
    },
  );
}

class _RulerSheet extends StatefulWidget {
  const _RulerSheet({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_RulerSheet> createState() => _RulerSheetState();
}

class _RulerSheetState extends State<_RulerSheet> {
  late int _value = widget.value.clamp(widget.min, widget.max);

  void _set(int next) {
    final clamped = next.clamp(widget.min, widget.max);
    setState(() => _value = clamped);
    widget.onChanged(clamped);
  }

  int _fromDx(double dx, double width) {
    if (width <= 0) {
      return _value;
    }
    final t = (dx / width).clamp(0.0, 1.0);
    final raw = widget.min + t * (widget.max - widget.min);
    return raw.round();
  }

  @override
  Widget build(BuildContext context) {
    final span = widget.max - widget.min;
    final minor = span <= 40 ? 1 : (span <= 120 ? 5 : 10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconTip(
              icon: Icons.check,
              message: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            widget.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_value',
            key: const ValueKey('ruler-value'),
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              height: 1,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                key: const ValueKey('ruler'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  _set(_fromDx(details.localPosition.dx, constraints.maxWidth));
                },
                onTapDown: (details) {
                  _set(_fromDx(details.localPosition.dx, constraints.maxWidth));
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 48),
                  painter: _RulerPainter(
                    value: _value,
                    min: widget.min,
                    max: widget.max,
                    minor: minor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.minor,
  });

  final int value;
  final int min;
  final int max;
  final int minor;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 10;
    final span = (max - min).toDouble();
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = AppColors.hairline
        ..strokeWidth = 2,
    );
    if (span <= 0) {
      return;
    }
    for (var tick = min; tick <= max; tick += minor) {
      final x = (tick - min) / span * size.width;
      final major = ((tick - min) ~/ minor) % 5 == 0;
      canvas.drawLine(
        Offset(x, baseline),
        Offset(x, baseline - (major ? 16 : 8)),
        Paint()
          ..color = major ? AppColors.muted : AppColors.hairline
          ..strokeWidth = major ? 1.4 : 1,
      );
    }
    final thumb = ((value.clamp(min, max) - min) / span) * size.width;
    canvas.drawCircle(
      Offset(thumb, baseline),
      7,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) => oldDelegate.value != value;
}
