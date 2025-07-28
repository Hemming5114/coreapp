import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/block_service.dart';
import 'user_detail_screen.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<Map<String, dynamic>> _followingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowingUsers();
  }

  Future<void> _loadFollowingUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 获取关注用户列表
      final followingUsers = await FollowService.getFollowingUsersWithData();
      
      // 过滤拉黑用户
      final filteredUsers = await BlockService.filterBlockedUsers(followingUsers);

      if (mounted) {
        setState(() {
          _followingUsers = filteredUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载关注用户失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '我的关注',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFE44D),
              ),
            )
          : _followingUsers.isEmpty
              ? _buildEmptyState()
              : _buildFollowingList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有关注任何人',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去发现更多有趣的人吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followingUsers.length,
      itemBuilder: (context, index) {
        final user = _followingUsers[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final String nickname = user['name'] ?? '未知用户';
    final String? avatar = user['head'];
    final String? personality = user['personality'];
    final int followersCount = user['fans'] ?? 0;

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
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
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
        title: Row(
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
        subtitle: Text(
          '$followersCount 粉丝',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '已关注',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: user),
            ),
          ).then((_) {
            // 从用户详情页返回后刷新列表
            _loadFollowingUsers();
          });
        },
      ),
    );
  }
} 