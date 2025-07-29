import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, dynamic>> _helpItems = [
    {
      'title': '如何发布动态？',
      'content': '在首页点击"+"按钮，选择"发布动态"，填写标题和内容，选择图片后点击发布即可。',
    },
    {
      'title': '如何找搭子？',
      'content': '在首页点击"+"按钮，选择"找搭子"，填写演出信息、主题、时间、地点等，上传封面图片后发布。',
    },
    {
      'title': '如何关注其他用户？',
      'content': '在用户详情页面点击"关注"按钮即可关注该用户，关注后可以查看其动态更新。',
    },
    {
      'title': '如何拉黑用户？',
      'content': '在用户详情页面点击"拉黑"按钮，或在设置页面的"拉黑管理"中管理已拉黑的用户。',
    },
    {
      'title': '如何举报不当内容？',
      'content': '在动态详情页面或用户详情页面点击"举报"按钮，选择举报原因并提交。',
    },
    {
      'title': '如何修改个人信息？',
      'content': '在"我的"页面点击右上角编辑按钮，可以修改头像、昵称、性格类型等个人信息。',
    },
    {
      'title': '什么是互动设置？',
      'content': '在设置页面可以管理关注列表、拉黑用户、查看举报历史等社交功能。',
    },
    {
      'title': '如何使用聊天功能？',
      'content': '点击"立即结伴"或"聊一下"按钮即可开始聊天，支持文字消息和表情互动。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '帮助中心',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 常见问题标题
          const Text(
            '常见问题',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 问题列表
          ..._helpItems.map((item) => _buildHelpItem(item)).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHelpItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          item['title'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        children: [
          Text(
            item['content'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 