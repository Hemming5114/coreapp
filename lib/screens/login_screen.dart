import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../services/keychain_service.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isAgreed = false;
  bool _isLoading = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _toggleAgreement() {
    if (_isLoading) return; // loading时禁用交互
    setState(() {
      _isAgreed = !_isAgreed;
    });
  }

  void _showShakeEffect() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  Future<void> _enterApp() async {
    if (_isLoading) return; // loading时禁用交互
    
    if (!_isAgreed) {
      _showShakeEffect();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用智谱AI生成用户昵称
      final nickname = await _generateNickname();
      
      if (nickname != null) {
        // 生成用户模型
        final userModel = _createUserModel(nickname);
        
        // 保存到keychain
        final success = await KeychainService.saveUserInfo(userModel.toJson());
        
        if (success) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          _showErrorDialog('保存用户信息失败，请稍后再试');
        }
      } else {
        _showErrorDialog('进入APP失败，请稍后再试');
      }
    } catch (e) {
      debugPrint('进入APP失败: $e');
      _showErrorDialog('进入APP失败，请稍后再试');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _generateNickname() async {
    try {
      final response = await ApiService.sendMessage(
        '请根据以下用户昵称的风格，生成一个类似的昵称，字数控制在2-10个字之间，只返回昵称，不要其他内容。参考昵称：咕噜噜、火野喵oxo、纠结的ijie小姐、列列ii、双下巴分你一半、豚豚奶糖、小狗凉茶好好喝、小美咯、鱼丸粗面、周周、esther、suey、池小小、喝奶茶长大的kiki、每天吃七次薯条、奶茶小仙女、泡泡的快乐星球、双层猫猫汉堡堡、苏小姐、我超爱学习的、鱼籽蛋花汤、bebe、emo的小狐狸、Mia-xiao、suinyuyu、sun、Y.寒寒'
      );
      
      if (response != null && response.isNotEmpty) {
        // 清理响应内容，只保留昵称
        final cleanNickname = response.trim().replaceAll(RegExp(r'[^\u4e00-\u9fa5a-zA-Z0-9]'), '');
        if (cleanNickname.length >= 2 && cleanNickname.length <= 10) {
          return cleanNickname;
        }
      }
      return null;
    } catch (e) {
      debugPrint('生成昵称失败: $e');
      return null;
    }
  }

  UserModel _createUserModel(String nickname) {
    final random = Random();
    
    // 随机选择头像 (user_head_30.webp ~ user_head_40.webp)
    final avatarNumber = random.nextInt(11) + 30; // 30-40
    final avatarPath = 'user_head_$avatarNumber.webp';
    
    return UserModel(
      name: nickname,
      userId: random.nextInt(900000) + 100000, // 6位数
      coins: random.nextInt(9000) + 1000, // 4位数
      membershipExpiry: DateTime.now().add(const Duration(days: 365)), // 一年后
      personality: random.nextBool() ? 'icon_i.webp' : 'icon_e.webp',
      head: avatarPath,
      originalHead: avatarPath, // 保存原始头像
      followCount: random.nextInt(10) + 1, // 1-10关注
      fansCount: random.nextInt(1000) + 100, // 100-1100粉丝
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主内容
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/appicon/bg_login.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _enterApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFCF15D),
                        foregroundColor: const Color(0xFF171717),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '进入APP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _shakeAnimation.value * 10 * sin(_shakeAnimation.value * 10),
                          0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _toggleAgreement,
                              child: Image.asset(
                                _isAgreed 
                                  ? 'assets/images/appicon/btn_login_ok_2.webp'
                                  : 'assets/images/appicon/btn_login_no_1.webp',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  // 如果图片加载失败，使用自定义勾选框作为备用
                                  return Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _isAgreed ? const Color(0xFFFCF15D) : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _isAgreed ? const Color(0xFFFCF15D) : Colors.grey[400]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _isAgreed
                                        ? const Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Color(0xFF171717),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                children: [
                                  const TextSpan(text: '我已阅读并同意'),
                                  TextSpan(
                                    text: '《用户协议》',
                                    style: const TextStyle(
                                      color: Color(0xFF73C5FF),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        if (_isLoading) return; // loading时禁用交互
                                        // 打开用户协议
                                        debugPrint('打开用户协议');
                                      },
                                  ),
                                  const TextSpan(text: '和'),
                                  TextSpan(
                                    text: '《隐私授权协议》',
                                    style: const TextStyle(
                                      color: Color(0xFF73C5FF),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        if (_isLoading) return; // loading时禁用交互
                                        // 打开隐私协议
                                        debugPrint('打开隐私协议');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          
          // Loading遮罩层
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: SpinKitFadingCircle(
                  color: Color(0xFFFCF15D),
                  size: 50.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 