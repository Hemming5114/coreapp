import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../models/user_model.dart';
import 'keychain_service.dart';

class InAppPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static late StreamSubscription<List<PurchaseDetails>> _subscription;
  static bool _isInitialized = false;

  /// 初始化内购
  static Future<bool> initialize() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('In-app purchases not available');
        return false;
      }

      // 监听购买更新
      final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (List<PurchaseDetails> purchaseDetailsList) {
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onDone: () {
          _subscription.cancel();
        },
        onError: (Object error) {
          debugPrint('Purchase stream error: $error');
        },
      );

      _isInitialized = true;
      debugPrint('In-app purchase initialized successfully');
      return true;
    } catch (e) {
      debugPrint('初始化内购失败: $e');
      return false;
    }
  }

  /// 购买产品
  static Future<bool> purchaseProduct(String productId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // 查询产品详情
      const Set<String> productIds = {
        'com.yeliao.shanliana60',
        'com.yeliao.shanliana300',
        'com.yeliao.shanliana1130',
        'com.yeliao.shanliana2350',
        'com.yeliao.shanliana3070',
        'com.yeliao.shanliana3600',
        'com.yeliao.shanliana0',
        'com.yeliao.shanliana1',
        'com.yeliao.shanliana2',
      };

      final ProductDetailsResponse productDetailResponse =
          await _inAppPurchase.queryProductDetails(productIds);

      if (productDetailResponse.error != null) {
        debugPrint('查询产品详情失败: ${productDetailResponse.error}');
        return false;
      }

      final ProductDetails? productDetails = productDetailResponse.productDetails
          .where((ProductDetails product) => product.id == productId)
          .firstOrNull;

      if (productDetails == null) {
        debugPrint('Product not found: $productId');
        return false;
      }

      // 创建购买参数
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // 发起购买
      final bool success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      debugPrint('购买失败: $e');
      return false;
    }
  }

  /// 恢复购买
  static Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('恢复购买失败: $e');
      return false;
    }
  }

  /// 处理购买更新
  static void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('Purchase status: ${purchaseDetails.status}');
      debugPrint('Product ID: ${purchaseDetails.productID}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchaseDetails.productID}');
          break;
        case PurchaseStatus.purchased:
          debugPrint('Purchase successful: ${purchaseDetails.productID}');
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchaseDetails.error}');
          break;
        case PurchaseStatus.restored:
          debugPrint('Purchase restored: ${purchaseDetails.productID}');
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled: ${purchaseDetails.productID}');
          break;
      }

      // 完成购买
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// 处理成功的购买
  static void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      await _updateUserDataAfterPurchase(purchaseDetails.productID);
      debugPrint('用户数据更新成功: ${purchaseDetails.productID}');
    } catch (e) {
      debugPrint('更新用户数据失败: $e');
    }
  }

  /// 购买成功后更新用户数据
  static Future<void> _updateUserDataAfterPurchase(String productId) async {
    try {
      // 获取当前用户数据
      final userInfo = await KeychainService.getUserInfo();
      if (userInfo == null) return;

      final userData = UserModel.fromJson(userInfo);
      
      // 根据产品ID更新用户数据
      UserModel updatedUser;
      
      if (_isCoinProduct(productId)) {
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
      }
      
      // 保存更新后的用户数据
      await KeychainService.saveUserInfo(updatedUser.toJson());
      debugPrint('用户数据更新成功: ${updatedUser.toString()}');
      
    } catch (e) {
      debugPrint('更新用户数据失败: $e');
    }
  }

  /// 判断是否为金币产品
  static bool _isCoinProduct(String productId) {
    const coinProducts = [
      'com.yeliao.shanliana60',
      'com.yeliao.shanliana300',
      'com.yeliao.shanliana1130',
      'com.yeliao.shanliana2350',
      'com.yeliao.shanliana3070',
      'com.yeliao.shanliana3600',
    ];
    return coinProducts.contains(productId);
  }

  /// 根据产品ID获取金币数量
  static int _getCoinsByProductId(String productId) {
    switch (productId) {
      case 'com.yeliao.shanliana60':
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
      case 'com.yeliao.shanliana0': // 月会员首充
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
    if (_isInitialized) {
      _subscription.cancel();
      _isInitialized = false;
    }
  }
} 