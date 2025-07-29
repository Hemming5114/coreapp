import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/keychain_service.dart';
import '../widgets/user_music_preferences_widget.dart';
import 'user_detail_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChatDetailScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userInfo = await KeychainService.getUserInfo();
      if (mounted) {
        setState(() {
          _currentUser = userInfo;
        });
      }
    } catch (e) {
      debugPrint('加载当前用户信息失败: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final userId = widget.userData['id']?.toString() ?? '';
      final messages = await ChatService.getMessages(userId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('加载消息失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final userId = widget.userData['id']?.toString() ?? '';
      final currentUserId = _currentUser?['id']?.toString() ?? '';
      
      final message = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': currentUserId,
        'content': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'text',
      };

      // 保存消息
      await ChatService.saveMessage(userId, message);
      
      // 更新聊天会话
      await ChatService.saveChat({
        'userId': userId,
        'userData': widget.userData,
        'lastMessage': text,
        'lastMessageTime': message['timestamp'],
      });

      // 清空输入框
      _messageController.clear();

      // 重新加载消息
      await _loadMessages();
    } catch (e) {
      debugPrint('发送消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('发送失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(widget.userData['name'] ?? widget.userData['nickname'] ?? widget.userData['userName'] ?? '聊天'),
        backgroundColor: const Color(0xFFF7F8FA),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白收起键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
        children: [
          // 用户信息卡
          _buildUserInfoCard(),
          
          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFE44D),
                    ),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          '开始聊天吧',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9598AC),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(_messages[index]);
                        },
                      ),
          ),
          
          // 输入框
          _buildInputArea(),
        ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final String nickname = widget.userData['name'] ?? 
                           widget.userData['nickname'] ?? 
                           widget.userData['userName'] ?? 
                           '未知用户';
    final String? avatar = widget.userData['head'] ?? 
                          widget.userData['avatar'] ?? 
                          widget.userData['userHead'];
    final String? personality = widget.userData['personality'];
    final String? loveSinger = widget.userData['lovesinger'] ?? 
                              widget.userData['loveSinger'];
    final String? loveSong = widget.userData['lovesong'] ?? 
                            widget.userData['loveSong'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              user: widget.userData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 头像
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: avatar != null && avatar.isNotEmpty
                        ? Image.asset(
                            'assets/images/head/$avatar',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF9598AC),
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF9598AC),
                              size: 30,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 用户信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            nickname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (personality != null && personality.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/appicon/$personality',
                              width: 36,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(width: 36, height: 20);
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 音乐偏好
            UserMusicPreferencesWidget(
              loveSinger: loveSinger,
              loveSong: loveSong,
              isOwn: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final String senderId = message['senderId']?.toString() ?? '';
    final String currentUserId = _currentUser?['id']?.toString() ?? '';
    final bool isMe = senderId == currentUserId;
    final String content = message['content'] ?? '';
    final int timestamp = message['timestamp'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 消息气泡
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFFE44D) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.black : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe 
                          ? Colors.black.withValues(alpha: 0.6)
                          : const Color(0xFF9598AC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9598AC),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 发送按钮
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending 
                    ? const Color(0xFF9598AC) 
                    : const Color(0xFFFFE44D),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      size: 20,
                      color: Colors.black,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(int timestamp) {
    final DateTime now = DateTime.now();
    final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    if (now.difference(messageTime).inDays == 0) {
      // 今天
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(messageTime).inDays < 7) {
      // 一周内
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return '${weekdays[messageTime.weekday - 1]} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (now.year == messageTime.year) {
      // 今年
      return '${messageTime.month.toString().padLeft(2, '0')}-${messageTime.day.toString().padLeft(2, '0')} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 其他年份
      return '${messageTime.year}-${messageTime.month.toString().padLeft(2, '0')}-${messageTime.day.toString().padLeft(2, '0')} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 