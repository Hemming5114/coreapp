import 'dart:io';
import 'moment_service.dart';
import 'partner_service.dart';

class DataMigrationService {
  // 清理无效的数据（图片文件不存在的数据）
  static Future<void> cleanupInvalidData() async {
    // 暂时禁用自动清理，避免误删有效数据
    // await _cleanupInvalidMoments();
    // await _cleanupInvalidPartnerRequests();
    print('数据清理已暂时禁用，如需清理请手动调用 clearAllCachedData()');
  }
  
  // 清理无效的动态数据
  static Future<void> _cleanupInvalidMoments() async {
    try {
      final moments = await MomentService.getMoments();
      List<Map<String, dynamic>> validMoments = [];
      
      for (var moment in moments) {
        bool isValid = true;
        
        // 检查图片是否存在
        if (moment['images'] != null && moment['images'] is List) {
          final images = (moment['images'] as List<dynamic>).cast<String>();
          for (String imagePath in images) {
            if (imagePath.isNotEmpty && !await File(imagePath).exists()) {
              isValid = false;
              break;
            }
          }
        }
        
        if (isValid) {
          validMoments.add(moment);
        } else {
          print('删除无效动态: ${moment['id']} - 图片文件不存在');
        }
      }
      
      // 如果有数据被删除，重新保存
      if (validMoments.length != moments.length) {
        await MomentService.clearAllMoments();
        for (var moment in validMoments) {
          await MomentService.saveMoment(moment);
        }
        print('清理完成：保留 ${validMoments.length} 个有效动态，删除 ${moments.length - validMoments.length} 个无效动态');
      }
    } catch (e) {
      print('清理动态数据失败: $e');
    }
  }
  
  // 清理无效的找搭子数据
  static Future<void> _cleanupInvalidPartnerRequests() async {
    try {
      final partnerRequests = await PartnerService.getPartnerRequests();
      List<Map<String, dynamic>> validRequests = [];
      
      for (var request in partnerRequests) {
        bool isValid = true;
        
        // 检查封面图片是否存在
        if (request['coverImage'] != null && request['coverImage'] is String) {
          final imagePath = request['coverImage'] as String;
          if (imagePath.isNotEmpty && !await File(imagePath).exists()) {
            isValid = false;
          }
        }
        
        if (isValid) {
          validRequests.add(request);
        } else {
          print('删除无效找搭子: ${request['id']} - 图片文件不存在');
        }
      }
      
      // 如果有数据被删除，重新保存
      if (validRequests.length != partnerRequests.length) {
        await PartnerService.clearAllPartnerRequests();
        for (var request in validRequests) {
          await PartnerService.savePartnerRequest(request);
        }
        print('清理完成：保留 ${validRequests.length} 个有效找搭子，删除 ${partnerRequests.length - validRequests.length} 个无效找搭子');
      }
    } catch (e) {
      print('清理找搭子数据失败: $e');
    }
  }
  
  // 强制清空所有缓存数据（作为最后的手段）
  static Future<void> clearAllCachedData() async {
    try {
      await MomentService.clearAllMoments();
      await PartnerService.clearAllPartnerRequests();
      print('已清空所有缓存数据');
    } catch (e) {
      print('清空缓存数据失败: $e');
    }
  }
} 