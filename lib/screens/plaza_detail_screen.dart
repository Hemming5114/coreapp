import 'package:flutter/material.dart';
import 'report_screen.dart';
import 'user_detail_screen.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class PlazaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Color cardColor;
  const PlazaDetailScreen({Key? key, required this.event, required this.cardColor}) : super(key: key);

  @override
  State<PlazaDetailScreen> createState() => _PlazaDetailScreenState();
}

class _PlazaDetailScreenState extends State<PlazaDetailScreen> {
  // 处理GO一起作伴点击事件
  Future<void> _handleJoinEvent() async {
    try {
      // 获取活动发布者信息
      final rawUserData = widget.event['userData'] ?? widget.event;
      final userData = Map<String, dynamic>.from(rawUserData);
      final String userId = userData['id']?.toString() ?? '';
      
      if (userId.isEmpty) {
        throw Exception('用户信息不完整');
      }

      // 检查是否已经存在聊天记录
      final existingChats = await ChatService.getChats();
      final existingChat = existingChats.firstWhere(
        (chat) => chat['userId'] == userId,
        orElse: () => <String, dynamic>{},
      );

      if (existingChat.isNotEmpty) {
        // 已经有聊天记录，直接进入聊天详情
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                userData: userData,
              ),
            ),
          );
        }
        return;
      }

      // 没有聊天记录，生成打招呼文案
      // 显示加载状态
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFE44D),
          ),
        ),
      );

      // 获取活动信息用于生成打招呼文案
      final String eventTitle = widget.event['title'] ?? '';
      final String venue = widget.event['location'] ?? '';
      final String eventDate = widget.event['time'] ?? '';
      
      // 构建AI请求内容
      final String prompt = '''
请为一个音乐现场活动生成一个20-50字的打招呼文案。
活动信息：
- 活动名称：$eventTitle
- 演出场地：$venue
- 演出时间：$eventDate

要求：
1. 文案要热情友好，体现对音乐的热爱
2. 自然地表达想要一起去看演出的意愿
3. 字数控制在20-50字之间
4. 语气轻松自然，不要太正式
''';

      // 调用AI生成打招呼文案
      final greetingMessage = await ApiService.sendMessage(prompt);
      
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (greetingMessage != null && greetingMessage.isNotEmpty) {
        // 创建聊天会话并发送打招呼消息
        await ChatService.createChat(userData, initialMessage: greetingMessage);
        
        if (mounted) {
          // 进入聊天详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                userData: userData,
              ),
            ),
          );
        }
      } else {
        throw Exception('生成打招呼文案失败');
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('进入聊天失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('GO一起作伴失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topBarHeight = 220 + MediaQuery.of(context).padding.top;
    // 广场banner下方内容间距，假设为20px
    const double contentTopMargin = 20;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 顶部色块背景
          Container(
            height: topBarHeight,
            color: widget.cardColor,
          ),
          // 头部内容（色块内）
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                // 顶部导航栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      GestureDetector(
                        onTap: () {
                          // 使用event中的完整用户数据
                          if (widget.event['userData'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailScreen(
                                  user: widget.event['userData'],
                                ),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          backgroundImage: AssetImage('assets/images/head/${widget.event['userHead']}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.event['userName'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.error_outline, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportScreen(
                                data: widget.event,
                                reportType: 'plaza',
                                title: '举报活动',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // 主图和标题等
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 主图+描述内容
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/iconImg/${widget.event['images']?[0] ?? ''}',
                              width: 96,
                              height: 127,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // 半透明蒙层
                          Container(
                            width: 96,
                            height: 127,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                          // 描述内容
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Text(
                              widget.event['content'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event['title'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF171717)),
                            ),
                            const SizedBox(height: 12),
                            Text('时间：${widget.event['time'] ?? ''}', style: const TextStyle(fontSize: 15, color: Color(0xFF171717))),
                            const SizedBox(height: 6),
                            Text('场馆：${widget.event['location'] ?? ''}', style: const TextStyle(fontSize: 15, color: Color(0xFF171717))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: contentTopMargin),
              ],
            ),
          ),
          // 白色内容区（详情及后续，覆盖在色块背景上，顶部margin与广场banner一致，圆角12）
          Positioned(
            top: topBarHeight - 12, // 让圆角正好覆盖色块底部
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('详情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF171717))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 20, color: Color(0xFF171717)),
                      const SizedBox(width: 6),
                      Text('主题：${widget.event['topic'] ?? ''}', style: const TextStyle(fontSize: 15, color: Color(0xFF171717))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Color(0xFF171717)),
                      const SizedBox(width: 6),
                      Text('集合时间：${widget.event['time']?.split(' ')[0] ?? ''}', style: const TextStyle(fontSize: 15, color: Color(0xFF171717))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Color(0xFF171717)),
                      const SizedBox(width: 6),
                      Text('集结地：${widget.event['location'] ?? ''}', style: const TextStyle(fontSize: 15, color: Color(0xFF171717))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('主题描述', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF171717))),
                  const SizedBox(height: 8),
                  Text(widget.event['content'] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFF171717))),
                  const SizedBox(height: 24),
                  const Text('成员', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF171717))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/head/${widget.event['userHead']}',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('想邀请1人，还差一人', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE44D),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _handleJoinEvent,
                        child: const Text('🤟 GO! 一起作伴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 