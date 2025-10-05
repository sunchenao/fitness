import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';

class ExerciseCounterWidget extends StatefulWidget {
  final int count;
  final int targetCount;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExerciseCounterWidget({
    super.key,
    required this.count,
    required this.targetCount,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ExerciseCounterWidget> createState() => _ExerciseCounterWidgetState();
}

class _ExerciseCounterWidgetState extends State<ExerciseCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: AppConstants.primaryColor,
      end: AppConstants.successColor,
    ).animate(_animationController);

    _previousCount = widget.count;
  }

  @override
  void didUpdateWidget(ExerciseCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检测计数增加
    if (widget.count > _previousCount) {
      _triggerCountAnimation();
      _previousCount = widget.count;
    }
  }

  void _triggerCountAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // 触觉反馈
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? AppConstants.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: _colorAnimation.value ?? AppConstants.primaryColor,
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 主计数显示
                  Text(
                    widget.count.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _colorAnimation.value ?? AppConstants.primaryColor,
                      height: 1.0,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 目标计数显示
                  Text(
                    '/ ${widget.targetCount}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 状态指示器
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive 
                          ? AppConstants.successColor 
                          : AppConstants.textHintColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}