import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../engine/plan.dart';
import '../export/format.dart';
import '../theme/app_theme.dart';

class RunView extends StatelessWidget {
  const RunView({
    super.key,
    required this.label,
    required this.seconds,
    required this.progress,
    required this.elapsed,
    required this.paused,
    required this.tint,
    required this.ring,
    required this.onPause,
    required this.onStop,
  });

  final String label;
  final int seconds;
  final double progress;
  final Duration elapsed;
  final bool paused;
  final Color tint;
  final Color ring;
  final VoidCallback onPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: tint,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              label,
              key: const ValueKey('run-label'),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: _RingPainter(progress: progress, color: ring),
                child: Center(child: _Count(seconds: seconds)),
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Row(
                children: [
                  _Elapsed(elapsed: elapsed),
                  const Spacer(),
                  _RoundButton(
                    icon: paused ? Icons.play_arrow : Icons.pause,
                    message: paused ? 'Resume' : 'Pause',
                    fill: AppColors.canvas,
                    iconColor: AppColors.ink,
                    onPressed: onPause,
                  ),
                  const SizedBox(width: 14),
                  _RoundButton(
                    icon: Icons.close,
                    message: 'Stop',
                    fill: AppColors.stop,
                    iconColor: Colors.white,
                    onPressed: onStop,
                    diameter: 68,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 168,
      fontWeight: FontWeight.w900,
      height: 0.85,
      letterSpacing: -6,
      color: AppColors.ink,
    );
    return SizedBox(
      width: 250,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 46),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Text(
                '$seconds',
                style: style.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$seconds',
              key: const ValueKey('run-seconds'),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _Elapsed extends StatelessWidget {
  const _Elapsed({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('run-elapsed'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Text(
            fmtElapsed(elapsed),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.message,
    required this.fill,
    required this.iconColor,
    required this.onPressed,
    this.diameter = 60,
  });

  final IconData icon;
  final String message;
  final Color fill;
  final Color iconColor;
  final VoidCallback onPressed;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: Material(
        color: fill,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

Color tintFor(PhaseKind kind) {
  return switch (kind) {
    PhaseKind.work => AppColors.workTint,
    PhaseKind.rest => AppColors.restTint,
    PhaseKind.setRest => AppColors.setRestTint,
    PhaseKind.cooldown => AppColors.cooldownTint,
    PhaseKind.prep => AppColors.canvas,
  };
}

Color ringFor(PhaseKind kind) {
  return switch (kind) {
    PhaseKind.work => AppColors.accent,
    PhaseKind.rest || PhaseKind.setRest => const Color(0xFF64748B),
    PhaseKind.prep || PhaseKind.cooldown => AppColors.ink,
  };
}
