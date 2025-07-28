import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/keychain_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _requestNetwork();
    _checkUserAndNavigate();
  }

  Future<void> _requestNetwork() async {
    try {
      await ApiService.testNetworkConnection();
    } catch (e) {
      debugPrint('网络请求失败: $e');
    }
  }

  Future<void> _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // 检查是否存在用户信息
      final userInfo = await KeychainService.getUserInfo();
      
      if (userInfo != null && userInfo.isNotEmpty) {
        // 用户信息存在，进入主页
        debugPrint('SplashScreen - 用户信息存在，进入主页');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // 用户信息不存在，进入登录页
        debugPrint('SplashScreen - 用户信息不存在，进入登录页');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('处理用户信息失败: $e');
      // 出错时默认进入登录页
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/appicon/bg_login.webp'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
} 