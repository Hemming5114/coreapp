import 'package:shared_preferences/shared_preferences.dart';

/// VIP首充状态管理服务
class FirstPurchaseService {
  static const String _firstPurchaseKey = 'vip_first_purchase_completed';
  
  /// 检查是否已经完成首充
  static Future<bool> hasCompletedFirstPurchase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_firstPurchaseKey) ?? false;
    } catch (e) {
      print('检查首充状态失败: $e');
      return false;
    }
  }
  
  /// 标记首充已完成
  static Future<void> markFirstPurchaseCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstPurchaseKey, true);
      print('✅ 首充状态已保存');
    } catch (e) {
      print('❌ 保存首充状态失败: $e');
    }
  }
  
  /// 清除首充状态（用于测试或重置）
  static Future<void> clearFirstPurchaseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_firstPurchaseKey);
      print('🗑️ 首充状态已清除');
    } catch (e) {
      print('❌ 清除首充状态失败: $e');
    }
  }
} 