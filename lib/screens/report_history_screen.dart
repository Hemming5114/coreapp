import 'package:flutter/material.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '举报历史',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              '暂无举报记录',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF9598AC),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '您还没有举报过任何内容',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9598AC),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 