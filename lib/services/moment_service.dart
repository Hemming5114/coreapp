import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_storage_service.dart';

class MomentService {
  static const String _momentsKey = 'user_moments';

  // 保存动态数据
  static Future<bool> saveMoment(Map<String, dynamic> data) async {
    try {
      // 获取现有数据
      final existingData = await getMoments();
      
      // 添加新数据
      existingData.add(data);
      
      // 保存到本地
      final jsonString = jsonEncode(existingData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_momentsKey, jsonString);
      
      return true;
    } catch (e) {
      print('保存动态数据失败: $e');
      return false;
    }
  }

  // 获取所有动态数据
  static Future<List<Map<String, dynamic>>> getMoments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_momentsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('读取动态数据失败: $e');
      return [];
    }
  }

  // 删除动态数据
  static Future<bool> deleteMoment(String id) async {
    try {
      final existingData = await getMoments();
      
      // 找到要删除的动态，获取其图片路径
      final momentToDelete = existingData.firstWhere(
        (item) => item['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      
      // 删除关联的图片文件
      if (momentToDelete.isNotEmpty && momentToDelete['images'] != null) {
        final images = (momentToDelete['images'] as List<dynamic>).cast<String>();
        await ImageStorageService.deleteImages(images);
      }
      
      final updatedData = existingData.where((item) => item['id'] != id).toList();
      
      final jsonString = jsonEncode(updatedData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_momentsKey, jsonString);
      
      return true;
    } catch (e) {
      print('删除动态数据失败: $e');
      return false;
    }
  }

  // 更新动态数据状态
  static Future<bool> updateMomentStatus(String id, String status) async {
    try {
      final existingData = await getMoments();
      
      for (var item in existingData) {
        if (item['id'] == id) {
          item['status'] = status;
          break;
        }
      }
      
      final jsonString = jsonEncode(existingData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_momentsKey, jsonString);
      
      return true;
    } catch (e) {
      print('更新动态数据状态失败: $e');
      return false;
    }
  }

  // 清空所有动态数据
  static Future<bool> clearAllMoments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_momentsKey);
      return true;
    } catch (e) {
      print('清空动态数据失败: $e');
      return false;
    }
  }
} 