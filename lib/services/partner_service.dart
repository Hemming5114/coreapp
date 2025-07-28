import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_storage_service.dart';

class PartnerService {
  static const String _partnerRequestsKey = 'partner_requests';

  // 保存找搭子数据
  static Future<bool> savePartnerRequest(Map<String, dynamic> data) async {
    try {
      // 获取现有数据
      final existingData = await getPartnerRequests();
      
      // 添加新数据
      existingData.add(data);
      
      // 保存到本地
      final jsonString = jsonEncode(existingData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_partnerRequestsKey, jsonString);
      
      return true;
    } catch (e) {
      print('保存找搭子数据失败: $e');
      return false;
    }
  }

  // 获取所有找搭子数据
  static Future<List<Map<String, dynamic>>> getPartnerRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_partnerRequestsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('读取找搭子数据失败: $e');
      return [];
    }
  }

  // 删除找搭子数据
  static Future<bool> deletePartnerRequest(String id) async {
    try {
      final existingData = await getPartnerRequests();
      
      // 找到要删除的找搭子数据，获取其图片路径
      final partnerToDelete = existingData.firstWhere(
        (item) => item['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      
      // 删除关联的图片文件
      if (partnerToDelete.isNotEmpty && partnerToDelete['coverImage'] != null) {
        await ImageStorageService.deleteImage(partnerToDelete['coverImage']);
      }
      
      final updatedData = existingData.where((item) => item['id'] != id).toList();
      
      final jsonString = jsonEncode(updatedData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_partnerRequestsKey, jsonString);
      
      return true;
    } catch (e) {
      print('删除找搭子数据失败: $e');
      return false;
    }
  }

  // 更新找搭子数据状态
  static Future<bool> updatePartnerRequestStatus(String id, String status) async {
    try {
      final existingData = await getPartnerRequests();
      
      for (var item in existingData) {
        if (item['id'] == id) {
          item['status'] = status;
          break;
        }
      }
      
      final jsonString = jsonEncode(existingData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_partnerRequestsKey, jsonString);
      
      return true;
    } catch (e) {
      print('更新找搭子数据状态失败: $e');
      return false;
    }
  }

  // 清空所有找搭子数据
  static Future<bool> clearAllPartnerRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_partnerRequestsKey);
      return true;
    } catch (e) {
      print('清空找搭子数据失败: $e');
      return false;
    }
  }
} 