import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _activityNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '通知设置',
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
          
          // 推送通知
          _buildSettingItem(
            title: '推送通知',
            subtitle: '接收应用推送消息',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
              activeColor: const Color(0xFFFFE44D),
            ),
          ),
          
          // 消息通知
          _buildSettingItem(
            title: '消息通知',
            subtitle: '新消息提醒',
            trailing: Switch(
              value: _messageNotifications,
              onChanged: (value) {
                setState(() {
                  _messageNotifications = value;
                });
              },
              activeColor: const Color(0xFFFFE44D),
            ),
          ),
          
          // 活动通知
          _buildSettingItem(
            title: '活动通知',
            subtitle: '新活动、关注更新等',
            trailing: Switch(
              value: _activityNotifications,
              onChanged: (value) {
                setState(() {
                  _activityNotifications = value;
                });
              },
              activeColor: const Color(0xFFFFE44D),
            ),
          ),
          
          const Divider(height: 32),
          
          // 声音
          _buildSettingItem(
            title: '声音',
            subtitle: '通知时播放声音',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
              activeColor: const Color(0xFFFFE44D),
            ),
          ),
          
          // 震动
          _buildSettingItem(
            title: '震动',
            subtitle: '通知时震动提醒',
            trailing: Switch(
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
              },
              activeColor: const Color(0xFFFFE44D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
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
        trailing: trailing,
      ),
    );
  }
} 