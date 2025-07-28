import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class FollowService {
  static const String _followingKey = 'following_users';
  static const String _followersKey = 'followers_count';
  static const String _followingDataKey = 'following_users_data';

  // 获取当前用户关注的所有用户ID
  static Future<Set<String>> getFollowingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final followingJson = prefs.getString(_followingKey);
    
    if (followingJson == null) {
      return <String>{};
    }

    try {
      final List<dynamic> followingList = jsonDecode(followingJson);
      return followingList.map((id) => id.toString()).toSet();
    } catch (e) {
      debugPrint('Error parsing following users: $e');
      return <String>{};
    }
  }

  // 获取关注用户的完整数据
  static Future<List<Map<String, dynamic>>> getFollowingUsersWithData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followingDataJson = prefs.getString(_followingDataKey);
      
      if (followingDataJson == null) {
        return [];
      }

      final List<dynamic> followingDataList = jsonDecode(followingDataJson);
      return followingDataList.map((userData) => Map<String, dynamic>.from(userData)).toList();
    } catch (e) {
      debugPrint('Error parsing following users data: $e');
      return [];
    }
  }

  // 关注用户
  static Future<void> followUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final following = await getFollowingUsers();
    following.add(userId);
    
    final followingJson = jsonEncode(following.toList());
    await prefs.setString(_followingKey, followingJson);
  }

  // 关注用户（保存完整用户数据）
  static Future<void> followUserWithData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = userData['id']?.toString() ?? '';
      
      if (userId.isEmpty) return;

      // 保存用户ID到关注列表
      final following = await getFollowingUsers();
      following.add(userId);
      final followingJson = jsonEncode(following.toList());
      await prefs.setString(_followingKey, followingJson);

      // 保存完整用户数据
      final followingData = await getFollowingUsersWithData();
      final existingIndex = followingData.indexWhere((user) => user['id']?.toString() == userId);
      
      if (existingIndex == -1) {
        // 新关注用户，添加到列表
        followingData.add(userData);
      } else {
        // 已存在，更新数据
        followingData[existingIndex] = userData;
      }
      
      final followingDataJson = jsonEncode(followingData);
      await prefs.setString(_followingDataKey, followingDataJson);
    } catch (e) {
      debugPrint('Error following user with data: $e');
    }
  }

  // 取消关注用户
  static Future<void> unfollowUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final following = await getFollowingUsers();
    following.remove(userId);
    
    final followingJson = jsonEncode(following.toList());
    await prefs.setString(_followingKey, followingJson);

    // 从完整数据中移除
    final followingData = await getFollowingUsersWithData();
    followingData.removeWhere((user) => user['id']?.toString() == userId);
    final followingDataJson = jsonEncode(followingData);
    await prefs.setString(_followingDataKey, followingDataJson);
  }

  // 检查是否关注了某个用户
  static Future<bool> isFollowing(String userId) async {
    final following = await getFollowingUsers();
    return following.contains(userId);
  }

  // 获取用户的粉丝数（基础数据 + 本地变化）
  static Future<int> getUserFollowersCount(String userId, int baseFollowers) async {
    final prefs = await SharedPreferences.getInstance();
    final followersJson = prefs.getString('${_followersKey}_$userId');
    
    if (followersJson == null) {
      return baseFollowers;
    }

    try {
      final Map<String, dynamic> followersData = jsonDecode(followersJson);
      final int localChange = followersData['change'] ?? 0;
      return baseFollowers + localChange;
    } catch (e) {
      debugPrint('Error parsing followers count: $e');
      return baseFollowers;
    }
  }

  // 增加用户粉丝数
  static Future<void> increaseFollowers(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final followersJson = prefs.getString('${_followersKey}_$userId');
    
    Map<String, dynamic> followersData;
    if (followersJson == null) {
      followersData = {'change': 1};
    } else {
      try {
        followersData = jsonDecode(followersJson);
        followersData['change'] = (followersData['change'] ?? 0) + 1;
      } catch (e) {
        followersData = {'change': 1};
      }
    }
    
    await prefs.setString('${_followersKey}_$userId', jsonEncode(followersData));
  }

  // 减少用户粉丝数
  static Future<void> decreaseFollowers(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final followersJson = prefs.getString('${_followersKey}_$userId');
    
    Map<String, dynamic> followersData;
    if (followersJson == null) {
      followersData = {'change': -1};
    } else {
      try {
        followersData = jsonDecode(followersJson);
        followersData['change'] = (followersData['change'] ?? 0) - 1;
      } catch (e) {
        followersData = {'change': -1};
      }
    }
    
    await prefs.setString('${_followersKey}_$userId', jsonEncode(followersData));
  }

  // 清除所有关注数据（用于测试或重置）
  static Future<void> clearAllFollowData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_followingKey);
    await prefs.remove(_followingDataKey);
    
    // 清除所有粉丝数变化数据
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('${_followersKey}_')) {
        await prefs.remove(key);
      }
    }
  }
} 