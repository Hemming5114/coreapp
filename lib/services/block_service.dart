import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BlockService {
  static const String _blockedUsersKey = 'blocked_users';

  // 获取拉黑用户列表（返回List<Map<String, dynamic>>）
  static Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_blockedUsersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('获取拉黑用户列表失败: $e');
      return [];
    }
  }

  // 拉黑用户（保存完整用户信息）
  static Future<bool> blockUser(Map<String, dynamic> userData) async {
    try {
      final blockedUsers = await getBlockedUsers();
      final userId = userData['id']?.toString() ?? '';
      final userName = userData['name'] ?? '未知用户';
      
      debugPrint('BlockService: 准备拉黑用户 - ID: $userId, 姓名: $userName');
      
      if (userId.isEmpty) {
        debugPrint('BlockService: 拉黑失败 - 用户ID为空');
        return false;
      }
      
      final alreadyBlocked = blockedUsers.any((u) => u['id']?.toString() == userId);
      if (!alreadyBlocked) {
        blockedUsers.add(userData);
        final jsonString = jsonEncode(blockedUsers);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_blockedUsersKey, jsonString);
        
        debugPrint('BlockService: 成功拉黑用户 - ID: $userId, 姓名: $userName');
        debugPrint('BlockService: 当前拉黑用户总数: ${blockedUsers.length}');
      } else {
        debugPrint('BlockService: 用户已经被拉黑 - ID: $userId, 姓名: $userName');
      }
      return true;
    } catch (e) {
      debugPrint('拉黑用户失败: $e');
      return false;
    }
  }

  // 取消拉黑用户
  static Future<bool> unblockUser(String userId) async {
    try {
      final blockedUsers = await getBlockedUsers();
      blockedUsers.removeWhere((u) => u['id']?.toString() == userId);
      final jsonString = jsonEncode(blockedUsers);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blockedUsersKey, jsonString);
      return true;
    } catch (e) {
      debugPrint('取消拉黑用户失败: $e');
      return false;
    }
  }

  // 检查用户是否被拉黑
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final blockedUsers = await getBlockedUsers();
      return blockedUsers.any((u) => u['id']?.toString() == userId);
    } catch (e) {
      debugPrint('检查用户拉黑状态失败: $e');
      return false;
    }
  }

  // 过滤拉黑用户的数据
  static Future<List<Map<String, dynamic>>> filterBlockedUsers(List<Map<String, dynamic>> data) async {
    try {
      final blockedUsers = await getBlockedUsers();
      final blockedIds = blockedUsers.map((u) => u['id']?.toString()).toSet();
      
      debugPrint('BlockService: 拉黑用户ID列表: $blockedIds');
      debugPrint('BlockService: 原始数据数量: ${data.length}');
      
      final filtered = data.where((item) {
        // 尝试多种方式获取用户ID，并统一转换为字符串
        final userId = item['userId']?.toString() ?? 
                      item['id']?.toString() ?? 
                      item['userData']?['id']?.toString() ?? 
                      item['user']?['id']?.toString() ?? '';
        
        debugPrint('BlockService: 检查用户ID: $userId, 用户名: ${item['userName'] ?? item['name'] ?? '未知'}');
        
        final isBlocked = blockedIds.contains(userId);
        if (isBlocked) {
          debugPrint('BlockService: 过滤掉用户ID: $userId, 用户名: ${item['userName'] ?? item['name'] ?? '未知'}');
        }
        
        return !isBlocked;
      }).toList();
      
      debugPrint('BlockService: 过滤后数据数量: ${filtered.length}');
      return filtered;
    } catch (e) {
      debugPrint('过滤拉黑用户数据失败: $e');
      return data;
    }
  }
} 