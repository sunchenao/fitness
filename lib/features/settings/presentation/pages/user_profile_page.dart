import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '个人资料页面',
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