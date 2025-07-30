import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/chat_service.dart';
import '../services/block_service.dart';
import 'chat_detail_screen.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  bool _hasInitialized = false;
  StreamSubscription<BlockEvent>? _blockEventSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChats();
    _listenToBlockEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blockEventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 如果已经初始化过，说明是从其他页面返回，需要刷新数据
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadChats();
        }
      });
    }
  }

  // 监听拉黑事件
  void _listenToBlockEvents() {
    _blockEventSubscription = BlockService.blockEventStream.listen((event) {
      if (mounted) {
        _handleBlockEvent(event);
      }
    });
  }

  // 处理拉黑事件
  void _handleBlockEvent(BlockEvent event) {
    setState(() {
      if (event.type == BlockEventType.blocked) {
        // 立即从列表中移除被拉黑用户的聊天记录
        _chats.removeWhere((chat) {
          final userId = chat['userId']?.toString() ?? '';
          return userId == event.userId;
        });
      } else if (event.type == BlockEventType.unblocked) {
        // 解除拉黑时重新加载数据以还原被解除拉黑用户的聊天记录
        _loadChats();
      }
    });
  }

  // Public refresh method, for external calls or user-triggered refresh
  void refreshData() {
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> allChats = await ChatService.getChats();
      
      // 拉黑过滤
      final filtered = await BlockService.filterBlockedUsers(allChats);
      
      if (mounted) {
        setState(() {
          _chats = filtered;
          _isLoading = false;
          _hasInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    final double safeTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // 背景图
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/appicon/bg_moment.webp',
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
            ),
          ),
          // 消息标题
          Positioned(
            top: safeTop,
            left: 16,
            child: Container(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景图片
                  Image.asset(
                    'assets/images/appicon/icon_moment_tab.webp',
                    width: 44,
                    height: 24,
                    fit: BoxFit.contain,
                    ),
                  // 文字
                  const Text(
                    '消息',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 内容区域
          Positioned(
            top: safeTop + 60,
            left: 0,
            right: 0,
            bottom: 0,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFE44D),
                    ),
                  )
                : _chats.isEmpty
                    ? _buildEmptyState()
                    : _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Color(0xFF9598AC),
          ),
          SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF9598AC),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '快去结识新朋友吧',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9598AC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChatItem(chat),
        );
      },
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final userData = chat['userData'] as Map<String, dynamic>;
    final String nickname = userData['name'] ?? 
                           userData['nickname'] ?? 
                           userData['userName'] ?? 
                           '未知用户';
    final String? avatar = userData['head'] ?? 
                          userData['avatar'] ?? 
                          userData['userHead'];
    final String? personality = userData['personality'];
    final String lastMessage = chat['lastMessage'] ?? '';
    final int? lastMessageTime = chat['lastMessageTime'];
    final String userId = chat['userId']?.toString() ?? '';

    return Slidable(
      key: Key('chat_$userId'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              await _showDeleteConfirmDialog(userId, nickname);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                userData: userData,
              ),
            ),
          ).then((_) {
            // 聊天页面返回后刷新列表
            _loadChats();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              // 头像
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: avatar != null && avatar.isNotEmpty
                      ? Image.asset(
                          'assets/images/head/$avatar',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF9598AC),
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF9598AC),
                            size: 24,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 消息内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 昵称和性格标识
                    Row(
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        if (personality != null && personality.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/images/appicon/$personality',
                            width: 29,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(width: 29, height: 16);
                            },
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 最后一条消息
                    Text(
                      lastMessage.isNotEmpty ? lastMessage : '开始聊天吧',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9598AC),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 时间
              if (lastMessageTime != null)
                Text(
                  ChatService.formatMessageTime(lastMessageTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9598AC),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(String userId, String nickname) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '删除聊天',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Text(
            '确定要删除与 $nickname 的聊天记录吗？\n删除后将无法恢复。',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                '删除',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteChat(userId, nickname);
    }
  }

  Future<void> _deleteChat(String userId, String nickname) async {
    try {
      final success = await ChatService.deleteChat(userId);
      if (success) {
        // 刷新聊天列表
        _loadChats();
        
        // 显示删除成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除与 $nickname 的聊天'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 显示删除失败提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除聊天失败，请重试'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('删除聊天失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除聊天失败，请重试'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

} 