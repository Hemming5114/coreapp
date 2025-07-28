import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  static const String _apiKey = '842370724dfa455487f16b1898f77ff8.XiwJjovFzYO0GKPO';
  
  static Future<bool> testNetworkConnection() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': [
            {
              'role': 'user',
              'content': '你好，这是一个网络连接测试'
            }
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('API响应状态码: ${response.statusCode}');
      debugPrint('API响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'] != null && data['choices'].isNotEmpty;
      } else if (response.statusCode == 401) {
        debugPrint('API密钥验证失败');
        return false;
      } else {
        debugPrint('API请求失败，状态码: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('网络连接测试失败: $e');
      return false;
    }
  }
  
  static Future<String?> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': [
            {
              'role': 'user',
              'content': message
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      return null;
    } catch (e) {
      debugPrint('发送消息失败: $e');
      return null;
    }
  }
} 