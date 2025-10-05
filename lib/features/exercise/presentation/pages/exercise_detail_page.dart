import 'package:flutter/material.dart';

class ExerciseDetailPage extends StatelessWidget {
  final String? exerciseType;

  const ExerciseDetailPage({super.key, this.exerciseType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('运动详情 - ${exerciseType ?? "未知"}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('运动详情页面'),
            if (exerciseType != null)
              Text('运动类型: $exerciseType'),
            const SizedBox(height: 20),
            const Text('（待实现）'),
          ],
        ),
      ),
    );
  }
}