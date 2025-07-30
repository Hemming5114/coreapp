import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/keychain_service.dart';
import '../models/user_model.dart';
import 'coin_recharge_screen.dart';
import 'vip_recharge_screen.dart';

class AIContentGeneratorScreen extends StatefulWidget {
  final String title; // "期望详情" 或 "动态内容"
  final String hintText; // 提示文案
  final String type; // "partner" 或 "moment"
  
  const AIContentGeneratorScreen({
    super.key,
    required this.title,
    required this.hintText,
    required this.type,
  });

  @override
  State<AIContentGeneratorScreen> createState() => _AIContentGeneratorScreenState();
}

class _AIContentGeneratorScreenState extends State<AIContentGeneratorScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  bool _isGenerating = false;
  bool _hasGenerated = false;
  
  // 用户数据相关
  UserModel? _userData;
  int _todayGenerateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _resultController.dispose();
    super.dispose();
  }
  
  // 强制移除焦点并收起键盘
  void _clearFocusAndDismissKeyboard() {
    // 1. 清除输入框的组合状态
    _keywordController.clearComposing();
    _resultController.clearComposing();
    
    // 2. 立即移除焦点
    FocusScope.of(context).unfocus();
    
    // 3. 确保当前焦点节点失去焦点
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild!.unfocus();
    }
    
    // 4. 延迟确保彻底清除焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      // 再次确保任何子焦点节点都失去焦点
      final currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        currentFocus.focusedChild!.unfocus();
      }
    });
    
    // 5. 延迟更久一点，确保键盘完全收起
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final currentContext = context;
        if (currentContext.mounted) {
          FocusScope.of(currentContext).unfocus();
        }
      }
    });
  }
  
  // 加载用户数据
  Future<void> _loadUserData() async {
    try {
      final userInfo = await KeychainService.getUserInfo();
      if (userInfo != null && userInfo.isNotEmpty) {
        setState(() {
          _userData = UserModel.fromJson(userInfo);
        });
        // 加载今日生成次数
        await _loadTodayGenerateCount();
      }
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
    }
  }
  
  // 加载今日生成次数
  Future<void> _loadTodayGenerateCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'ai_generate_count_${today.year}_${today.month}_${today.day}';
      
      final count = prefs.getInt(todayKey) ?? 0;
      setState(() {
        _todayGenerateCount = count;
      });
    } catch (e) {
      debugPrint('加载今日AI生成次数失败: $e');
    }
  }

  // 检查生成限制
  Future<bool> _checkGenerateLimit() async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户信息加载失败，请重试')),
      );
      return false;
    }
    
    // 检查是否是VIP
    final isVip = _isVipActive();
    if (isVip) {
      return true; // VIP无限生成
    }
    
    // 检查今日生成次数
    final remainingFreeCount = 3 - _todayGenerateCount;
    
    if (remainingFreeCount > 0) {
      // 还有免费机会
      return await _showFreeGenerateDialog(remainingFreeCount);
    } else {
      // 没有免费机会，检查金币
      if (_userData!.coins >= 10) {
        // 金币充足
        return await _showCoinGenerateDialog();
      } else {
        // 金币不足
        return await _showInsufficientCoinDialog();
      }
    }
  }
  
  // 检查VIP状态
  bool _isVipActive() {
    if (_userData?.membershipExpiry == null) return false;
    return DateTime.now().isBefore(_userData!.membershipExpiry);
  }
  
  // 显示免费生成确认弹框
  Future<bool> _showFreeGenerateDialog(int remainingCount) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '确认生成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _clearFocusAndDismissKeyboard();
                  Navigator.of(context).pop(false);
                },
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '您今天还有 '),
                    TextSpan(
                      text: '$remainingCount',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' 次免费AI生成机会\n\n确定要生成文案吗？'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE44D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '成为VIP会员后可无限制AI生成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _clearFocusAndDismissKeyboard();
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: const Color(0xFF666666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _clearFocusAndDismissKeyboard();
                      Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE44D),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '生成',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 显示金币生成弹框
  Future<bool> _showCoinGenerateDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '生成确认',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _clearFocusAndDismissKeyboard();
                  Navigator.of(context).pop(false);
                },
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '您的免费生成次数已用完\n\n生成将消耗 '),
                    TextSpan(
                      text: '10金币',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，当前余额：'),
                    TextSpan(
                      text: '${_userData!.coins}金币',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '选择生成方式：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFE44D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '成为VIP会员后可无限制AI生成',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _clearFocusAndDismissKeyboard();
                          Navigator.of(context).pop(true);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '使用金币生成',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _clearFocusAndDismissKeyboard();
                          Navigator.of(context).pop(false);
                          _navigateToVip();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE44D),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '成为VIP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 显示金币不足弹框
  Future<bool> _showInsufficientCoinDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  size: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '金币不足',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _clearFocusAndDismissKeyboard();
                  Navigator.of(context).pop(false);
                },
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '您的免费生成次数已用完\n\nAI生成需要 '),
                    TextSpan(
                      text: '10金币',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，当前余额：'),
                    TextSpan(
                      text: '${_userData!.coins}金币',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '请选择：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFE44D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '成为VIP会员后可无限制AI生成',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _clearFocusAndDismissKeyboard();
                          Navigator.of(context).pop(false);
                          _navigateToCoinRecharge();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '去充值',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _clearFocusAndDismissKeyboard();
                          Navigator.of(context).pop(false);
                          _navigateToVip();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE44D),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '成为VIP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 导航到金币充值页面
  void _navigateToCoinRecharge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoinRechargeScreen(
          currentCoins: _userData?.coins ?? 0,
          onRechargeSuccess: () {
            _loadUserData(); // 刷新用户数据
          },
        ),
      ),
    );
  }
  
  // 导航到VIP充值页面
  void _navigateToVip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VipRechargeScreen(
          userData: _userData,
          onRechargeSuccess: () {
            _loadUserData(); // 刷新用户数据
          },
        ),
      ),
    );
  }
  
  // 扣除金币
  Future<void> _deductCoins() async {
    if (_userData == null) return;
    
    try {
      // 扣除10金币
      final newCoins = _userData!.coins - 10;
      final updatedUserData = UserModel(
        name: _userData!.name,
        userId: _userData!.userId,
        coins: newCoins,
        membershipExpiry: _userData!.membershipExpiry,
        personality: _userData!.personality,
        head: _userData!.head,
        originalHead: _userData!.originalHead,
        lovesinger: _userData!.lovesinger,
        lovesong: _userData!.lovesong,
        followCount: _userData!.followCount,
        fansCount: _userData!.fansCount,
      );
      
      // 保存更新后的用户数据
      final success = await KeychainService.saveUserInfo(updatedUserData.toJson());
      if (success) {
        setState(() {
          _userData = updatedUserData;
        });
        debugPrint('扣除金币成功，当前余额：$newCoins');
      } else {
        debugPrint('扣除金币失败');
      }
    } catch (e) {
      debugPrint('扣除金币异常：$e');
    }
  }

  // 增加今日生成次数
  Future<void> _incrementGenerateCount() async {
    if (_userData == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'ai_generate_count_${today.year}_${today.month}_${today.day}';

      final count = prefs.getInt(todayKey) ?? 0;
      final newCount = count + 1;

      await prefs.setInt(todayKey, newCount);
      setState(() {
        _todayGenerateCount = newCount;
      });
      debugPrint('今日AI生成次数增加成功，当前次数：$newCount');
    } catch (e) {
      debugPrint('增加今日AI生成次数失败: $e');
    }
  }

  // 生成AI文案
  Future<void> _generateContent() async {
    final keyword = _keywordController.text.trim();
    
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入关键词')),
      );
      return;
    }

    if (keyword.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('关键词至少需要2个字符')),
      );
      return;
    }

    // 先收起键盘，在弹框之前
    _clearFocusAndDismissKeyboard();
    
    // 等待键盘完全收起
    await Future.delayed(const Duration(milliseconds: 300));

    // 检查生成限制
    final canGenerate = await _checkGenerateLimit();
    if (!canGenerate) {
      // 如果生成被取消，确保键盘不会重新弹出
      _clearFocusAndDismissKeyboard();
      return;
    }

    // 再次确保键盘收起，在开始生成之前
    _clearFocusAndDismissKeyboard();

    setState(() {
      _isGenerating = true;
    });

    try {
      String prompt;
      if (widget.type == 'partner') {
        prompt = '请根据关键词"$keyword"生成一份找搭子的期望详情，要求：\n'
            '1. 字数在200-1000字之间\n'
            '2. 内容切合关键词，描述具体期望和安排\n'
            '3. 词藻优美，语言生动有趣\n'
            '4. 不涉及任何不健康内容\n'
            '5. 适合音乐演出或活动场景\n'
            '请直接输出生成的文案内容，不要包含其他说明文字。';
      } else {
        prompt = '请根据关键词"$keyword"生成一份动态分享内容，要求：\n'
            '1. 字数在200-1000字之间\n'
            '2. 内容切合关键词，描述印象深刻的现场瞬间\n'
            '3. 词藻优美，富有感染力\n'
            '4. 不涉及任何不健康内容\n'
            '5. 适合音乐现场或演出分享\n'
            '请直接输出生成的文案内容，不要包含其他说明文字。';
      }

      final response = await ApiService.sendMessage(prompt);
      
      if (response != null && response.trim().isNotEmpty) {
        setState(() {
          _resultController.text = response.trim();
          _hasGenerated = true;
        });
        
        // 生成成功后扣除金币和增加次数
        await _incrementGenerateCount();
        if (!_isVipActive() && _todayGenerateCount >= 3) {
          await _deductCoins();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文案生成成功！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成失败，请重试')),
        );
        // 如果生成失败，确保键盘不会重新弹出
        _clearFocusAndDismissKeyboard();
      }
    } catch (e) {
      debugPrint('AI文案生成失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后重试')),
      );
      // 如果发生异常，确保键盘不会重新弹出
      _clearFocusAndDismissKeyboard();
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // 使用生成的文案
  void _useGeneratedContent() {
    if (_resultController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先生成文案')),
      );
      return;
    }
    
    Navigator.of(context).pop(_resultController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'AI生成文案',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白收起键盘
          _clearFocusAndDismissKeyboard();
        },
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // 关键词输入
                      const Text(
                        '输入关键词',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _keywordController,
                          maxLength: 50,
                          decoration: const InputDecoration(
                            hintText: '输入你想要的主题关键词...',
                            hintStyle: TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 生成按钮（没有结果时显示）
                      if (!_hasGenerated)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isGenerating ? null : _generateContent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFE44D),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : const Text(
                                    '生成文案',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      
                      if (_hasGenerated) ...[
                        const SizedBox(height: 30),
                        
                        // 生成结果
                        const Text(
                          '生成结果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _resultController,
                            maxLines: 15,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 操作按钮区域
                        Row(
                          children: [
                            // 重新生成按钮
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isGenerating ? null : _generateContent,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFE44D),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    '重新生成',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 使用文案按钮
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _useGeneratedContent,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    '使用这个文案',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Loading遮罩层
          if (_isGenerating)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: SpinKitFadingCircle(
                  color: Color(0xFFFFE44D),
                  size: 50.0,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
} 