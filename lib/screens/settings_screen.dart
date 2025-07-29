import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'blocked_users_screen.dart';
import 'report_history_screen.dart';
import 'about_screen.dart';
import 'help_center_screen.dart';
import 'feedback_screen.dart';
import 'following_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // H5页面链接（稍后替换为实际链接）
  static const String _privacyPolicyUrl = 'https://example.com/privacy-policy';
  static const String _userAgreementUrl = 'https://example.com/user-agreement';

  // 打开隐私政策
  Future<void> _openPrivacyPolicy() async {
    try {
      final Uri url = Uri.parse(_privacyPolicyUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开隐私政策页面')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打开隐私政策页面失败')),
        );
      }
    }
  }

  // 打开用户协议
  Future<void> _openUserAgreement() async {
    try {
      final Uri url = Uri.parse(_userAgreementUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开用户协议页面')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打开用户协议页面失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '设置',
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
          
          // 互动设置
          _buildSection(
            title: '互动设置',
            items: [
              _buildSettingItem(
                icon: Icons.people_outline,
                title: '我的关注',
                subtitle: '管理关注列表',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FollowingScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.block,
                title: '拉黑管理',
                subtitle: '管理拉黑用户',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlockedUsersScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.report_outlined,
                title: '举报历史',
                subtitle: '查看举报记录',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 帮助与支持
          _buildSection(
            title: '帮助与支持',
            items: [
              _buildSettingItem(
                icon: Icons.help_outline,
                title: '帮助中心',
                subtitle: '常见问题解答',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.feedback_outlined,
                title: '意见反馈',
                subtitle: '提交建议和问题',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 法律条款
          _buildSection(
            title: '法律条款',
            items: [
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                subtitle: '了解隐私保护',
                onTap: () async {
                  await _openPrivacyPolicy();
                },
              ),
              _buildSettingItem(
                icon: Icons.description_outlined,
                title: '用户协议',
                subtitle: '服务条款和协议',
                onTap: () async {
                  await _openUserAgreement();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 关于
          _buildSection(
            title: '关于',
            items: [
              _buildSettingItem(
                icon: Icons.info_outline,
                title: '关于我们',
                subtitle: '了解应用信息',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
          child: Icon(
            icon,
            color: const Color(0xFFFFE44D),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF999999),
        ),
        onTap: onTap,
      ),
    );
  }
} 