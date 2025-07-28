import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String _chatsKey = 'user_chats';
  static const String _messagesPrefix = 'chat_messages_';

  // 保存聊天会话
  static Future<bool> saveChat(Map<String, dynamic> chatData) async {
    try {
      final existingChats = await getChats();
      
      // 检查是否已存在该用户的聊天
      final existingIndex = existingChats.indexWhere(
        (chat) => chat['userId'] == chatData['userId']
      );
      
      if (existingIndex >= 0) {
        // 更新现有聊天
        existingChats[existingIndex] = chatData;
      } else {
        // 添加新聊天
        existingChats.add(chatData);
      }
      
      // 按最后消息时间排序
      existingChats.sort((a, b) {
        final timeA = (a['lastMessageTime'] as int?) ?? 0;
        final timeB = (b['lastMessageTime'] as int?) ?? 0;
        return timeB.compareTo(timeA);
      });
      
      final jsonString = jsonEncode(existingChats);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatsKey, jsonString);
      
      return true;
    } catch (e) {
      print('保存聊天会话失败: $e');
      return false;
    }
  }

  // 获取所有聊天会话
  static Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('读取聊天会话失败: $e');
      return [];
    }
  }

  // 保存消息到特定聊天
  static Future<bool> saveMessage(String userId, Map<String, dynamic> message) async {
    try {
      final messages = await getMessages(userId);
      messages.add(message);
      
      final jsonString = jsonEncode(messages);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_messagesPrefix$userId', jsonString);
      
      // 更新聊天会话的最后一条消息
      await _updateLastMessage(userId, message);
      
      return true;
    } catch (e) {
      print('保存消息失败: $e');
      return false;
    }
  }

  // 获取特定用户的消息历史
  static Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_messagesPrefix$userId');
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('读取消息历史失败: $e');
      return [];
    }
  }

  // 更新聊天会话的最后一条消息
  static Future<void> _updateLastMessage(String userId, Map<String, dynamic> message) async {
    try {
      final chats = await getChats();
      final chatIndex = chats.indexWhere((chat) => chat['userId'] == userId);
      
      if (chatIndex >= 0) {
        chats[chatIndex]['lastMessage'] = message['content'];
        chats[chatIndex]['lastMessageTime'] = message['timestamp'];
        chats[chatIndex]['lastMessageType'] = message['type'];
        
        final jsonString = jsonEncode(chats);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_chatsKey, jsonString);
      }
    } catch (e) {
      print('更新最后消息失败: $e');
    }
  }

  // 创建新的聊天会话
  static Future<bool> createChat(Map<String, dynamic> userData, {String? initialMessage}) async {
    try {
      final chatData = {
        'userId': userData['id']?.toString() ?? '',
        'userData': userData,
        'lastMessage': initialMessage ?? '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      };
      
      await saveChat(chatData);
      
      // 如果有初始消息，保存它
      if (initialMessage != null && initialMessage.isNotEmpty) {
        // 获取当前用户ID (这里需要从KeychainService获取)
        final prefs = await SharedPreferences.getInstance();
        String currentUserId = '';
        try {
          final userInfoString = prefs.getString('user_info');
          if (userInfoString != null) {
            final userInfo = jsonDecode(userInfoString);
            currentUserId = userInfo['id']?.toString() ?? '';
          }
        } catch (e) {
          print('获取当前用户ID失败: $e');
        }
        
        final message = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'senderId': currentUserId,
          'content': initialMessage,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'text',
        };
        await saveMessage(userData['id']?.toString() ?? '', message);
      }
      
      return true;
    } catch (e) {
      print('创建聊天会话失败: $e');
      return false;
    }
  }

  // 删除聊天会话
  static Future<bool> deleteChat(String userId) async {
    try {
      // 删除聊天会话
      final chats = await getChats();
      final updatedChats = chats.where((chat) => chat['userId'] != userId).toList();
      
      final jsonString = jsonEncode(updatedChats);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatsKey, jsonString);
      
      // 删除消息历史
      await prefs.remove('$_messagesPrefix$userId');
      
      return true;
    } catch (e) {
      print('删除聊天会话失败: $e');
      return false;
    }
  }

  // 清空所有聊天数据
  static Future<void> clearAllChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatsKey);
      
      // 删除所有消息历史
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith(_messagesPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('清空聊天数据失败: $e');
    }
  }

  // 格式化消息时间显示
  static String formatMessageTime(int timestamp) {
    try {
      final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
      
      // 今天：时:分
      if (messageDate == today) {
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
      
      // 当周：周X 时:分
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      if (messageDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
          messageDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
        final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        final weekday = weekdays[messageTime.weekday - 1];
        return '$weekday ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
      
      // 当月：月-日 时:分
      if (messageTime.year == now.year && messageTime.month == now.month) {
        return '${messageTime.month}-${messageTime.day.toString().padLeft(2, '0')} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
      
      // 其他：年-月-日 时:分
      return '${messageTime.year}-${messageTime.month}-${messageTime.day.toString().padLeft(2, '0')} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      
    } catch (e) {
      return timestamp.toString();
    }
  }
} 