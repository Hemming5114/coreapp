import 'package:flutter/material.dart';
import '../services/native_purchase_service.dart';
import 'dart:async';

class CoinRechargeScreen extends StatefulWidget {
  final int currentCoins;
  final VoidCallback onRechargeSuccess;

  const CoinRechargeScreen({
    super.key,
    required this.currentCoins,
    required this.onRechargeSuccess,
  });

  @override
  State<CoinRechargeScreen> createState() => _CoinRechargeScreenState();
}

class _CoinRechargeScreenState extends State<CoinRechargeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  late int _displayCoins; // 用于显示的金币数量
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;

  final List<Map<String, dynamic>> _coinPackages = [
    {
      'productId': 'com.yeliao.shanliana60',
      'coins': 60,
      'price': 6,
    },
    {
      'productId': 'com.yeliao.shanliana300',
      'coins': 300,
      'price': 28,
    },
    {
      'productId': 'com.yeliao.shanliana1130',
      'coins': 1130,
      'price': 98,
    },
    {
      'productId': 'com.yeliao.shanliana2350',
      'coins': 2350,
      'price': 198,
    },
    {
      'productId': 'com.yeliao.shanliana3070',
      'coins': 3070,
      'price': 268,
    },
    {
      'productId': 'com.yeliao.shanliana3600',
      'coins': 3600,
      'price': 298,
    },
  ];

  @override
  void initState() {
    super.initState();
    _displayCoins = widget.currentCoins;
    _initializeAndListenToPurchaseEvents();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  /// 初始化并监听购买事件
  void _initializeAndListenToPurchaseEvents() async {
    // 初始化原生内购服务
    await NativePurchaseService.initialize();
    
    _purchaseSubscription = NativePurchaseService.purchaseEventStream.listen((event) {
      if (!mounted) return;
      
      // 只处理金币产品的购买事件
      final coinProductIds = _coinPackages.map((package) => package['productId'] as String).toSet();
      if (!coinProductIds.contains(event.productId)) {
        return; // 不是金币产品，忽略此事件
      }
      
      switch (event.result) {
        case PurchaseResult.success:
          if (event.updatedUserData != null) {
            setState(() {
              _displayCoins = event.updatedUserData!.coins;
              _isLoading = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(event.isRestored ? '金币权益已恢复！' : '金币充值成功！'),
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
              content: Text('充值失败：${event.errorMessage ?? "未知错误"}'),
              backgroundColor: Colors.red,
            ),
          );
          break;
          
        case PurchaseResult.canceled:
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('充值已取消')),
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
    final selectedPackage = _coinPackages[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '金币充值',
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
          // 当前金币显示
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '当前金币',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/appicon/icon_me_coin.webp',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_displayCoins',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8C00),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 档位选择列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _coinPackages.length,
                itemBuilder: (context, index) {
                  final package = _coinPackages[index];
                  final isSelected = index == _selectedIndex;

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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFE44D) : Colors.transparent,
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
                                color: isSelected ? const Color(0xFFFFE44D) : const Color(0xFFCCCCCC),
                                width: 2,
                              ),
                              color: isSelected ? const Color(0xFFFFE44D) : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // 金币数量
                          Image.asset(
                            'assets/images/appicon/icon_me_coin.webp',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${package['coins']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // 价格
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥${package['price']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
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

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedPackage = _coinPackages[_selectedIndex];
      final success = await NativePurchaseService.purchaseProduct(selectedPackage['productId']);
      
      if (!success && mounted) {
        // 购买请求失败
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('购买请求失败，请重试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('购买失败：$e')),
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
} 