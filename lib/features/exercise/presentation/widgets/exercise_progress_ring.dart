import 'dart:math' as math;
import 'package:flutter/material.dart';

class ExerciseProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final bool animated;
  final Duration animationDuration;

  const ExerciseProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.strokeWidth = 8,
    this.backgroundColor = Colors.grey,
    this.progressColor = Colors.blue,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ExerciseProgressRing> createState() => _ExerciseProgressRingState();
}

class _ExerciseProgressRingState extends State<ExerciseProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animated) {
      _animationController.forward();
    }
    
    _currentProgress = widget.progress;
  }

  @override
  void didUpdateWidget(ExerciseProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      _currentProgress = widget.progress;
      
      if (widget.animated) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.animated
          ? AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ProgressRingPainter(
                    progress: _progressAnimation.value,
                    strokeWidth: widget.strokeWidth,
                    backgroundColor: widget.backgroundColor,
                    progressColor: widget.progressColor,
                  ),
                );
              },
            )
          : CustomPaint(
              painter: ProgressRingPainter(
                progress: widget.progress,
                strokeWidth: widget.strokeWidth,
                backgroundColor: widget.backgroundColor,
                progressColor: widget.progressColor,
              ),
            ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // 添加渐变效果
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: [
          progressColor.withOpacity(0.3),
          progressColor,
          progressColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      progressPaint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // 从顶部开始
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // 绘制进度指示点
    if (progress > 0 && progress < 1.0) {
      final indicatorAngle = -math.pi / 2 + (2 * math.pi * progress);
      final indicatorX = center.dx + radius * math.cos(indicatorAngle);
      final indicatorY = center.dy + radius * math.sin(indicatorAngle);
      
      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(indicatorX, indicatorY),
        strokeWidth / 2 + 2,
        indicatorPaint,
      );

      final indicatorBorderPaint = Paint()
        ..color = progressColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(
        Offset(indicatorX, indicatorY),
        strokeWidth / 2 + 2,
        indicatorBorderPaint,
      );
    }

    // 完成时的特效
    if (progress >= 1.0) {
      final completePaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;

      // 绘制完成标记
      final checkPath = Path();
      final checkSize = radius * 0.3;
      final checkCenter = center;
      
      checkPath.moveTo(
        checkCenter.dx - checkSize * 0.5,
        checkCenter.dy,
      );
      checkPath.lineTo(
        checkCenter.dx - checkSize * 0.1,
        checkCenter.dy + checkSize * 0.3,
      );
      checkPath.lineTo(
        checkCenter.dx + checkSize * 0.5,
        checkCenter.dy - checkSize * 0.3,
      );

      final checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = strokeWidth / 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}