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
      'content': '在"我的"页面点击右上角编辑按钮，或在设置页面的"个人信息"中进行修改。',
    },
    {
      'title': '如何退出登录？',
      'content': '在设置页面底部点击"退出登录"按钮，确认后即可退出当前账号。',
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
        children: [
          const SizedBox(height: 16),
          
          // 搜索框
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索帮助内容...',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF999999),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 常见问题
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '常见问题',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 问题列表
          ..._helpItems.map((item) => _buildHelpItem(item)).toList(),
          
          const SizedBox(height: 32),
          
          // 联系客服
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE44D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Color(0xFFFFE44D),
                  size: 20,
                ),
              ),
              title: const Text(
                '联系客服',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              subtitle: const Text(
                '在线客服为您解答问题',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF999999),
              ),
              onTap: () {
                // TODO: 跳转到客服页面
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('客服功能开发中...')),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHelpItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        title: Text(
          item['title'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item['content'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 