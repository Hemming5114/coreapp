import 'package:flutter/material.dart';
import '../services/block_service.dart';
import 'user_detail_screen.dart';
import 'dart:async';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  StreamSubscription<BlockEvent>? _blockEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
    _listenToBlockEvents();
  }

  @override
  void dispose() {
    _blockEventSubscription?.cancel();
    super.dispose();
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
        // 有新用户被拉黑，添加到列表
        final userId = event.userId;
        final exists = _blockedUsers.any((user) => user['id']?.toString() == userId);
        if (!exists) {
          _blockedUsers.add(event.userData);
        }
      } else if (event.type == BlockEventType.unblocked) {
        // 用户被解除拉黑，从列表中移除
        _blockedUsers.removeWhere((user) => user['id']?.toString() == event.userId);
      }
    });
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final users = await BlockService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载拉黑用户列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('取消拉黑'),
          content: Text('确定要取消拉黑用户 "$userName" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await BlockService.unblockUser(userId);
        // 移除手动setState，让事件监听机制自动处理UI更新
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已取消拉黑用户 "$userName"'),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('操作失败，请重试'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('取消拉黑失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('操作失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '拉黑管理',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFE44D),
              ),
            )
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : _buildBlockedUsersList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16),
          Text(
            '暂无拉黑用户',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF9598AC),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '您还没有拉黑任何用户',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9598AC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
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
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5E5E5),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: user['head'] != null && user['head'].toString().isNotEmpty
                    ? Image.asset(
                        'assets/images/head/${user['head']}',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF9598AC),
                              size: 20,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF9598AC),
                          size: 20,
                        ),
                      ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  user['name'] ?? '未知用户',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (user['personality'] != null && user['personality'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/appicon/${user['personality']}',
                    width: 29,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 29, height: 16);
                    },
                  ),
                ],
              ],
            ),
            subtitle: const Text(
              '已拉黑',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9598AC),
              ),
            ),
            trailing: TextButton(
              onPressed: () => _unblockUser(
                user['id']?.toString() ?? '',
                user['name'] ?? '该用户',
              ),
              child: const Text(
                '取消拉黑',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 