import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/native_purchase_service.dart';
import '../services/first_purchase_service.dart';
import 'dart:async';

class VipRechargeScreen extends StatefulWidget {
  final UserModel? userData;
  final VoidCallback onRechargeSuccess;

  const VipRechargeScreen({
    super.key,
    required this.userData,
    required this.onRechargeSuccess,
  });

  @override
  State<VipRechargeScreen> createState() => _VipRechargeScreenState();
}

class _VipRechargeScreenState extends State<VipRechargeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  UserModel? _currentUserData; // 用于显示的用户数据
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;
  bool _hasCompletedFirstPurchase = false; // 是否已完成首充

  final List<Map<String, dynamic>> _vipPackages = [
    {
      'productId': 'com.yeliao.shanliana0',
      'title': '月会员首充',
      'price': 88,
      'duration': '1个月',
      'isFirstTime': true,
    },
    {
      'productId': 'com.yeliao.shanliana1',
      'title': '月会员',
      'price': 98,
      'duration': '1个月',
      'isFirstTime': false,
    },
    {
      'productId': 'com.yeliao.shanliana2',
      'title': '季度会员',
      'price': 268,
      'duration': '3个月',
      'isFirstTime': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _checkFirstPurchaseStatus();
    _initializeAndListenToPurchaseEvents();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  /// 检查首充状态
  void _checkFirstPurchaseStatus() async {
    try {
      final hasCompleted = await FirstPurchaseService.hasCompletedFirstPurchase();
      setState(() {
        _hasCompletedFirstPurchase = hasCompleted;
      });
      print('首充状态检查: ${hasCompleted ? "已完成" : "未完成"}');
    } catch (e) {
      print('检查首充状态失败: $e');
    }
  }

  /// 初始化并监听购买事件
  void _initializeAndListenToPurchaseEvents() async {
    // 初始化原生内购服务
    await NativePurchaseService.initialize();
    
    _purchaseSubscription = NativePurchaseService.purchaseEventStream.listen((event) {
      if (!mounted) return;
      
      // 只处理VIP产品的购买事件
      final vipProductIds = _vipPackages.map((package) => package['productId'] as String).toSet();
      if (!vipProductIds.contains(event.productId)) {
        return; // 不是VIP产品，忽略此事件
      }
      
      switch (event.result) {
        case PurchaseResult.success:
          if (event.updatedUserData != null) {
            setState(() {
              _currentUserData = event.updatedUserData!;
              _isLoading = false;
            });
            
            // 如果购买的是首充产品，更新首充状态
            if (event.productId == 'com.yeliao.shanliana0' && !event.isRestored) {
              setState(() {
                _hasCompletedFirstPurchase = true;
              });
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(event.isRestored ? 'VIP权益已恢复！' : 'VIP开通成功！'),
                backgroundColor: Colors.green,
              ),
            );
            
            // 调用成功回调
            widget.onRechargeSuccess();
          }
          break;
          
        case PurchaseResult.error:
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('开通失败：${event.errorMessage ?? "未知错误"}'),
              backgroundColor: Colors.red,
            ),
          );
          break;
          
        case PurchaseResult.canceled:
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('开通已取消')),
          );
          break;
          
        case PurchaseResult.pending:
          // 保持loading状态
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPackage = _vipPackages[_selectedIndex];
    final isVipActive = _isVipActive();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'VIP会员',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // VIP状态卡片
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 背景图
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    isVipActive 
                        ? 'assets/images/appicon/bg_vip_more_ing.webp'
                        : 'assets/images/appicon/bg_vip_more_no.webp',
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                // 左下角内容
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUserData?.name ?? '用户',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500, // Medium
                          color: isVipActive ? const Color(0xFF592D01) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVipActive ? _formatVipExpiry() : '还未开通VIP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // Medium
                          color: isVipActive ? const Color(0xFF592D01) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // VIP特权展示
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPrivilegeItem(
                  'assets/images/appicon/icon_me_vip_1.webp',
                  '专属标识',
                  '专属身份铭牌',
                ),
                _buildPrivilegeItem(
                  'assets/images/appicon/icon_me_vip_2.webp',
                  '无限找搭子',
                  '兴趣爱好早了解',
                ),
                _buildPrivilegeItem(
                  'assets/images/appicon/icon_me_vip_3.webp',
                  'AI赋能',
                  '头条由你决定',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 档位选择
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _vipPackages.length,
                itemBuilder: (context, index) {
                  final package = _vipPackages[index];
                  final isSelected = index == _selectedIndex;
                  final isFirstTimePackage = package['isFirstTime'] as bool;
                  final isFirstTimeUnavailable = isFirstTimePackage && _hasCompletedFirstPurchase;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isFirstTimeUnavailable ? Colors.grey[100] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFirstTimeUnavailable 
                              ? Colors.grey[300]! 
                              : (isSelected ? const Color(0xFFFFE44D) : Colors.transparent),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 选择状态指示器
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFirstTimeUnavailable 
                                    ? Colors.grey[400]!
                                    : (isSelected ? const Color(0xFFFFE44D) : const Color(0xFFCCCCCC)),
                                width: 2,
                              ),
                              color: isFirstTimeUnavailable 
                                  ? Colors.grey[300]
                                  : (isSelected ? const Color(0xFFFFE44D) : Colors.transparent),
                            ),
                            child: isSelected && !isFirstTimeUnavailable
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // 套餐信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      package['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isFirstTimeUnavailable ? Colors.grey[500] : Colors.black,
                                      ),
                                    ),
                                    if (isFirstTimePackage)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isFirstTimeUnavailable ? Colors.grey[400] : const Color(0xFFFF4444),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isFirstTimeUnavailable ? '已购买' : '首充特惠',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  package['duration'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isFirstTimeUnavailable ? Colors.grey[500] : const Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 价格
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥${package['price']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isFirstTimeUnavailable ? Colors.grey[500] : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 支付按钮
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFE44D),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      '立即支付 ¥${selectedPackage['price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeItem(String iconPath, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE44D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Image.asset(
              iconPath,
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.star,
                  size: 60,
                  color: Color(0xFFFFE44D),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _isVipActive() {
    if (_currentUserData?.membershipExpiry == null) return false;
    return DateTime.now().isBefore(_currentUserData!.membershipExpiry);
  }

  String _formatVipExpiry() {
    if (!_isVipActive()) return '未开通VIP';
    final expiry = _currentUserData!.membershipExpiry;
    return '${expiry.year}.${expiry.month.toString().padLeft(2, '0')}.${expiry.day.toString().padLeft(2, '0')}到期';
  }

  Future<void> _handlePurchase() async {
    final selectedPackage = _vipPackages[_selectedIndex];
    final isFirstTimePackage = selectedPackage['isFirstTime'] as bool;
    
    // 🚫 检查首充拦截
    if (isFirstTimePackage && _hasCompletedFirstPurchase) {
      _showFirstPurchaseCompletedDialog();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await NativePurchaseService.purchaseProduct(selectedPackage['productId']);
      
      if (!success && mounted) {
        // 购买请求失败
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开通请求失败，请重试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开通失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示首充已完成提示对话框
  void _showFirstPurchaseCompletedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('温馨提示'),
          content: const Text('您已经享受过首充特惠，请选择其他套餐。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 自动选择月会员套餐（非首充）
                setState(() {
                  _selectedIndex = 1; // 选择 com.yeliao.shanliana1 月会员
                });
              },
              child: const Text(
                '选择月会员',
                style: TextStyle(color: Color(0xFFFFE44D)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '知道了',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
} 