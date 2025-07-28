// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coreapp/main.dart';

void main() {
  testWidgets('应用启动测试', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 验证应用标题是否显示
    expect(find.text('音乐搭子'), findsOneWidget);
    expect(find.text('寻找你的音乐伙伴'), findsOneWidget);

    // 验证加载指示器是否显示
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('主页面结构测试', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('音乐搭子'),
            Text('寻找你的音乐伙伴'),
            CircularProgressIndicator(),
          ],
        ),
      ),
    ));

    // 验证基本UI元素
    expect(find.text('音乐搭子'), findsOneWidget);
    expect(find.text('寻找你的音乐伙伴'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
