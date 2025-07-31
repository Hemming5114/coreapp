import 'package:flutter/services.dart';
import 'dart:async';
import '../models/user_model.dart';
import 'keychain_service.dart';
import 'first_purchase_service.dart';

/// 原生内购事件
class NativePurchaseEvent {
  final String productId;
  final String status;
  final String? transactionId;
  final double? transactionDate;
  final String? receiptData;
  final String? errorMessage;
  final int? errorCode;

  NativePurchaseEvent({
    required this.productId,
    required this.status,
    this.transactionId,
    this.transactionDate,
    this.receiptData,
    this.errorMessage,
    this.errorCode,
  });

  factory NativePurchaseEvent.fromMap(Map<String, dynamic> map) {
    return NativePurchaseEvent(
      productId: map['productId'] ?? '',
      status: map['status'] ?? '',
      transactionId: map['transactionId'],
      transactionDate: map['transactionDate']?.toDouble(),
      receiptData: map['receiptData'],
      errorMessage: map['errorMessage'],
      errorCode: map['errorCode'],
    );
  }
}

/// 商品信息
class NativeProductInfo {
  final String productId;
  final String price;
  final String title;
  final String description;

  NativeProductInfo({
    required this.productId,
    required this.price,
    required this.title,
    required this.description,
  });

  factory NativeProductInfo.fromMap(Map<String, dynamic> map) {
    return NativeProductInfo(
      productId: map['productId'] ?? '',
      price: map['price'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

/// 购买结果枚举
enum PurchaseResult {
  success,
  error,
  canceled,
  pending,
}

/// 购买事件类
class PurchaseEvent {
  final String productId;
  final PurchaseResult result;
  final String? errorMessage;
  final UserModel? updatedUserData;
  final bool isRestored;

  PurchaseEvent({
    required this.productId,
    required this.result,
    this.errorMessage,
    this.updatedUserData,
    this.isRestored = false,
  });
}

/// 原生内购服务
class NativePurchaseService {
  static const MethodChannel _channel = MethodChannel('native_purchase_channel');
  
  // 事件流控制器
  static final StreamController<NativePurchaseEvent> _nativeEventController = 
      StreamController<NativePurchaseEvent>.broadcast();
  
  // 购买事件流控制器（兼容旧接口）
  static final StreamController<PurchaseEvent> _purchaseEventController = 
      StreamController<PurchaseEvent>.broadcast();
  
  static Stream<NativePurchaseEvent> get nativeEventStream => _nativeEventController.stream;
  static Stream<PurchaseEvent> get purchaseEventStream => _purchaseEventController.stream;
  
  static bool _isInitialized = false;

  // 产品配置
  static const Set<String> _coinProductIds = {
    '6_ml_coin',
    'com.yeliao.shanliana300',
    'com.yeliao.shanliana1130',
    'com.yeliao.shanliana2350',
    'com.yeliao.shanliana3070',
    'com.yeliao.shanliana3600',
  };
  
  // VIP首充产品ID
  static const String _firstPurchaseProductId = '88_ml_month';

  /// 初始化服务
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 设置方法调用处理器
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
    
    print('🎯 NativePurchaseService initialized');
  }

  /// 处理来自原生端的方法调用
  static Future<void> _handleMethodCall(MethodCall call) async {
    print('📱 Received native call: ${call.method}');
    
    switch (call.method) {
      case 'onProductsReceived':
        _handleProductsReceived(call.arguments);
        break;
        
      case 'onPurchaseUpdated':
        _handlePurchaseUpdated(call.arguments);
        break;
        
      case 'onPurchaseCompleted':
        _handlePurchaseCompleted(call.arguments);
        break;
        
      case 'onPurchaseFailed':
        _handlePurchaseFailed(call.arguments);
        break;
        
      case 'onPurchaseRestored':
        _handlePurchaseRestored(call.arguments);
        break;
        
      case 'onPurchaseDeferred':
        _handlePurchaseDeferred(call.arguments);
        break;
        
      default:
        print('⚠️ Unknown method call: ${call.method}');
    }
  }

  /// 检查设备是否支持内购
  static Future<bool> canMakePayments() async {
    try {
      final result = await _channel.invokeMethod('canMakePayments');
      return result as bool;
    } catch (e) {
      print('❌ Error checking payment availability: $e');
      return false;
    }
  }

  /// 请求商品信息
  static Future<List<NativeProductInfo>> requestProductInfo(List<String> productIds) async {
    try {
      final result = await _channel.invokeMethod('requestProductInfo', {
        'productIds': productIds,
      });
      
      if (result is List) {
        return result.map((item) => NativeProductInfo.fromMap(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error requesting product info: $e');
      return [];
    }
  }

  /// 购买商品
  static Future<bool> purchaseProduct(String productId) async {
    try {
      final isConsumable = _coinProductIds.contains(productId);
      
      await _channel.invokeMethod('purchaseProduct', {
        'productId': productId,
        'isConsumable': isConsumable,
      });
      return true;
    } catch (e) {
      print('❌ Error purchasing product: $e');
      return false;
    }
  }

  /// 完成交易
  static Future<void> finishTransaction(String transactionId) async {
    try {
      await _channel.invokeMethod('finishTransaction', {
        'transactionId': transactionId,
      });
      print('✅ Transaction finished: $transactionId');
    } catch (e) {
      print('❌ Error finishing transaction: $e');
    }
  }

  /// 恢复购买
  static Future<void> restorePurchases() async {
    try {
      await _channel.invokeMethod('restorePurchases');
    } catch (e) {
      print('❌ Error restoring purchases: $e');
    }
  }

  /// 处理商品信息接收
  static void _handleProductsReceived(dynamic arguments) {
    print('📦 Products received: $arguments');
    // 这里可以添加商品信息处理逻辑
  }

  /// 处理购买状态更新
  static void _handlePurchaseUpdated(dynamic arguments) {
    final event = NativePurchaseEvent.fromMap(Map<String, dynamic>.from(arguments));
    print('🔄 Purchase updated: ${event.productId} - ${event.status}');
    _nativeEventController.add(event);
    
    // 发送兼容事件
    _purchaseEventController.add(PurchaseEvent(
      productId: event.productId,
      result: PurchaseResult.pending,
    ));
  }

  /// 处理购买完成
  static void _handlePurchaseCompleted(dynamic arguments) async {
    final event = NativePurchaseEvent.fromMap(Map<String, dynamic>.from(arguments));
    print('✅ Purchase completed: ${event.productId}');
    _nativeEventController.add(event);
    
    // 🔥 关键：处理用户数据更新
    try {
      final updatedUserData = await _updateUserDataAfterPurchase(event.productId);
      
      if (updatedUserData != null) {
        // 🎉 如果是首充产品，保存首充状态
        if (event.productId == _firstPurchaseProductId) {
          await FirstPurchaseService.markFirstPurchaseCompleted();
          print('🎊 首充完成，状态已保存');
        }
        
        // 发送成功事件
        _purchaseEventController.add(PurchaseEvent(
          productId: event.productId,
          result: PurchaseResult.success,
          updatedUserData: updatedUserData,
          isRestored: false,
        ));
        
        // 完成交易
        if (event.transactionId != null) {
          await finishTransaction(event.transactionId!);
        }
      } else {
        throw Exception('用户数据更新失败');
      }
    } catch (e) {
      print('❌ Failed to update user data: $e');
      _purchaseEventController.add(PurchaseEvent(
        productId: event.productId,
        result: PurchaseResult.error,
        errorMessage: '数据更新失败: $e',
      ));
    }
  }

  /// 处理购买失败
  static void _handlePurchaseFailed(dynamic arguments) {
    final event = NativePurchaseEvent.fromMap(Map<String, dynamic>.from(arguments));
    print('❌ Purchase failed: ${event.productId} - ${event.errorMessage}');
    _nativeEventController.add(event);
    
    // 发送兼容事件
    _purchaseEventController.add(PurchaseEvent(
      productId: event.productId,
      result: PurchaseResult.error,
      errorMessage: event.errorMessage ?? '购买失败',
    ));
  }

  /// 处理购买恢复
  static void _handlePurchaseRestored(dynamic arguments) async {
    final event = NativePurchaseEvent.fromMap(Map<String, dynamic>.from(arguments));
    print('🔄 Purchase restored: ${event.productId}');
    _nativeEventController.add(event);
    
    // 🔥 对于恢复购买，只发送UI更新事件，不重复发放商品
    try {
      final userInfo = await KeychainService.getUserInfo();
      if (userInfo != null) {
        final userData = UserModel.fromJson(userInfo);
        
        _purchaseEventController.add(PurchaseEvent(
          productId: event.productId,
          result: PurchaseResult.success,
          updatedUserData: userData,
          isRestored: true,
        ));
      } else {
        _purchaseEventController.add(PurchaseEvent(
          productId: event.productId,
          result: PurchaseResult.success,
          isRestored: true,
        ));
      }
      
      // 完成恢复的交易
      if (event.transactionId != null) {
        await finishTransaction(event.transactionId!);
      }
    } catch (e) {
      print('❌ Failed to handle restored purchase: $e');
    }
  }

  /// 处理购买延期
  static void _handlePurchaseDeferred(dynamic arguments) {
    final event = NativePurchaseEvent.fromMap(Map<String, dynamic>.from(arguments));
    print('⏳ Purchase deferred: ${event.productId}');
    _nativeEventController.add(event);
    
    // 发送兼容事件
    _purchaseEventController.add(PurchaseEvent(
      productId: event.productId,
      result: PurchaseResult.pending,
    ));
  }

  /// 购买成功后更新用户数据
  static Future<UserModel?> _updateUserDataAfterPurchase(String productId) async {
    try {
      // 获取当前用户数据
      final userInfo = await KeychainService.getUserInfo();
      if (userInfo == null) {
        throw Exception('用户数据不存在，无法处理购买');
      }

      final userData = UserModel.fromJson(userInfo);
      
      // 根据产品ID更新用户数据
      UserModel updatedUser;
      
      if (_coinProductIds.contains(productId)) {
        // 金币产品
        final coins = _getCoinsByProductId(productId);
        updatedUser = UserModel(
          name: userData.name,
          userId: userData.userId,
          coins: userData.coins + coins,
          membershipExpiry: userData.membershipExpiry,
          personality: userData.personality,
          head: userData.head,
          originalHead: userData.originalHead,
          lovesinger: userData.lovesinger,
          lovesong: userData.lovesong,
          followCount: userData.followCount,
          fansCount: userData.fansCount,
        );
        print('💰 Added $coins coins to user account');
      } else {
        // VIP产品
        final months = _getMonthsByProductId(productId);
        final now = DateTime.now();
        final currentExpiry = userData.membershipExpiry;
        
        // 如果当前VIP已过期，从现在开始计算；否则从当前过期时间开始延长
        final newExpiry = currentExpiry.isAfter(now) 
            ? DateTime(currentExpiry.year, currentExpiry.month + months, currentExpiry.day)
            : DateTime(now.year, now.month + months, now.day);
            
        updatedUser = UserModel(
          name: userData.name,
          userId: userData.userId,
          coins: userData.coins,
          membershipExpiry: newExpiry,
          personality: userData.personality,
          head: userData.head,
          originalHead: userData.originalHead,
          lovesinger: userData.lovesinger,
          lovesong: userData.lovesong,
          followCount: userData.followCount,
          fansCount: userData.fansCount,
        );
        print('👑 Extended VIP membership by $months months');
      }
      
      // 保存更新后的用户数据
      await KeychainService.saveUserInfo(updatedUser.toJson());
      print('✅ User data updated successfully: ${updatedUser.toString()}');
      
      return updatedUser;
    } catch (e) {
      print('❌ Failed to update user data: $e');
      rethrow;
    }
  }

  /// 根据产品ID获取金币数量
  static int _getCoinsByProductId(String productId) {
    switch (productId) {
      case '6_ml_coin':
        return 60;
      case 'com.yeliao.shanliana300':
        return 300;
      case 'com.yeliao.shanliana1130':
        return 1130;
      case 'com.yeliao.shanliana2350':
        return 2350;
      case 'com.yeliao.shanliana3070':
        return 3070;
      case 'com.yeliao.shanliana3600':
        return 3600;
      default:
        return 0;
    }
  }

  /// 根据产品ID获取VIP月数
  static int _getMonthsByProductId(String productId) {
    switch (productId) {
      case '88_ml_month': // 月会员首充
      case 'com.yeliao.shanliana1': // 月会员
        return 1;
      case 'com.yeliao.shanliana2': // 季度会员
        return 3;
      default:
        return 0;
    }
  }

  /// 清理资源
  static void dispose() {
    _nativeEventController.close();
    _purchaseEventController.close();
    _isInitialized = false;
  }
} 