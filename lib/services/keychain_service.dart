import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class KeychainService {
  static const MethodChannel _channel = MethodChannel('keychain_service');
  
  static const String _userInfoKey = 'user_info';
  
  /// 保存用户信息到iOS keychain
  static Future<bool> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final jsonString = jsonEncode(userInfo);
      final result = await _channel.invokeMethod('saveToKeychain', {
        'key': _userInfoKey,
        'value': jsonString,
      });
      return result == true;
    } catch (e) {
      debugPrint('保存用户信息失败: $e');
      return false;
    }
  }
  
  /// 从iOS keychain获取用户信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final result = await _channel.invokeMethod('getFromKeychain', {
        'key': _userInfoKey,
      });
      
      if (result != null && result is String) {
        return jsonDecode(result) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return null;
    }
  }
  
  /// 从iOS keychain删除用户信息
  static Future<bool> deleteUserInfo() async {
    try {
      final result = await _channel.invokeMethod('deleteFromKeychain', {
        'key': _userInfoKey,
      });
      return result == true;
    } catch (e) {
      debugPrint('删除用户信息失败: $e');
      return false;
    }
  }
} 