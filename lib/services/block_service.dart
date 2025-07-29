import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
  static const String _blockedUsersKey = 'blocked_users';
  
  // Stream Controller for real-time block/unblock events
  static final StreamController<BlockEvent> _blockEventController = 
      StreamController<BlockEvent>.broadcast();
  
  // Public stream for listening to block events
  static Stream<BlockEvent> get blockEventStream => _blockEventController.stream;

  // 获取所有拉黑的用户
  static Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_blockedUsersKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('获取拉黑用户列表失败: $e');
      return [];
    }
  }

  // 拉黑用户（保存完整用户信息并广播事件）
  static Future<bool> blockUser(Map<String, dynamic> userData) async {
    try {
      final blockedUsers = await getBlockedUsers();
      final userId = userData['id']?.toString() ?? '';
      
      if (userId.isEmpty) {
        return false;
      }
      
      final alreadyBlocked = blockedUsers.any((u) => u['id']?.toString() == userId);
      if (!alreadyBlocked) {
        blockedUsers.add(userData);
        final jsonString = jsonEncode(blockedUsers);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_blockedUsersKey, jsonString);
        
        // 广播拉黑事件
        _blockEventController.add(BlockEvent(
          type: BlockEventType.blocked,
          userId: userId,
          userData: userData,
        ));
      }
      return true;
    } catch (e) {
      debugPrint('拉黑用户失败: $e');
      return false;
    }
  }

  // 解除拉黑用户并广播事件
  static Future<bool> unblockUser(String userId) async {
    try {
      final blockedUsers = await getBlockedUsers();
      final userData = blockedUsers.firstWhere(
        (user) => user['id']?.toString() == userId,
        orElse: () => <String, dynamic>{},
      );
      
      final updated = blockedUsers..removeWhere((user) => user['id']?.toString() == userId);
      final jsonString = jsonEncode(updated);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blockedUsersKey, jsonString);
      
      // 广播解除拉黑事件
      if (userData.isNotEmpty) {
        _blockEventController.add(BlockEvent(
          type: BlockEventType.unblocked,
          userId: userId,
          userData: userData,
        ));
      }
      
      return true;
    } catch (e) {
      debugPrint('解除拉黑失败: $e');
      return false;
    }
  }

  // 检查用户是否被拉黑
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final blockedUsers = await getBlockedUsers();
      return blockedUsers.any((user) => user['id']?.toString() == userId);
    } catch (e) {
      debugPrint('检查拉黑状态失败: $e');
      return false;
    }
  }

  // 过滤拉黑用户的数据
  static Future<List<Map<String, dynamic>>> filterBlockedUsers(List<Map<String, dynamic>> data) async {
    try {
      final blockedUsers = await getBlockedUsers();
      final blockedIds = blockedUsers.map((u) => u['id']?.toString()).toSet();
      
      final filtered = data.where((item) {
        final userId = item['userId']?.toString() ?? 
                      item['id']?.toString() ?? 
                      item['userData']?['id']?.toString() ?? 
                      item['user']?['id']?.toString() ?? '';
        
        return !blockedIds.contains(userId);
      }).toList();
      
      return filtered;
    } catch (e) {
      debugPrint('过滤拉黑用户数据失败: $e');
      return data;
    }
  }

  // 释放资源
  static void dispose() {
    _blockEventController.close();
  }
}

// 拉黑事件类型
enum BlockEventType {
  blocked,   // 拉黑
  unblocked, // 解除拉黑
}

// 拉黑事件数据
class BlockEvent {
  final BlockEventType type;
  final String userId;
  final Map<String, dynamic> userData;

  BlockEvent({
    required this.type,
    required this.userId,
    required this.userData,
  });
} 