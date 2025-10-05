import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '统计分析页面',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '（待实现）',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}