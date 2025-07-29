import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:convert';
import '../services/chat_service.dart';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const VideoCallScreen({super.key, required this.userData});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with WidgetsBindingObserver {
  bool _isCallEnded = false;
  String _callStatus = '正在等待对方接听...';
  Timer? _callTimer;
  Timer? _dotTimer;
  String _dots = '';
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioPlayer();
    _startCallTimer();
    _startDotAnimation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _dotTimer?.cancel();
    _stopAudio();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // 应用进入后台时继续播放音频
        break;
      case AppLifecycleState.resumed:
        // 应用恢复时检查是否需要继续播放
        if (!_isCallEnded) {
          _playCallSound();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _playCallSound();
  }

  Future<void> _playCallSound() async {
    if (_isCallEnded) return;
    
    try {
      await _audioPlayer.play(AssetSource('data/calling.m4a'));
      print('开始播放通话音频');
    } catch (e) {
      print('播放音频失败: $e');
      // 如果音频文件不存在，使用系统音效
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      print('停止播放通话音频');
    } catch (e) {
      print('停止音频失败: $e');
    }
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isCallEnded) {
        timer.cancel();
        return;
      }
      setState(() {
        _dots = _dots.length >= 3 ? '' : '$_dots.';
      });
    });
  }

  void _startCallTimer() {
    _callTimer = Timer(const Duration(minutes: 1), () {
      if (mounted && !_isCallEnded) {
        _handleCallTimeout();
      }
    });
  }

  Future<void> _handleCallTimeout() async {
    setState(() {
      _isCallEnded = true;
      _callStatus = '对方未接听';
    });

    await _stopAudio();

    // 添加未接通消息
    try {
      final message = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': widget.userData['id'].toString(),
        'content': '视频通话：对方未接通',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'text',
      };
      await ChatService.saveMessage(
        widget.userData['id'].toString(),
        message,
      );
    } catch (e) {
      debugPrint('保存通话记录失败: $e');
    }

    // 延迟返回
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleHangup() async {
    setState(() {
      _isCallEnded = true;
      _callStatus = '通话已取消';
    });

    await _stopAudio();

    // 添加取消通话消息
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentUserId = '';
      try {
        final userInfoString = prefs.getString('user_info');
        if (userInfoString != null) {
          final userInfo = jsonDecode(userInfoString);
          currentUserId = userInfo['id']?.toString() ?? '';
        }
      } catch (e) {
        debugPrint('获取当前用户ID失败: $e');
      }
      
      final message = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': currentUserId,
        'content': '视频通话：已取消',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'text',
      };
      await ChatService.saveMessage(
        widget.userData['id'].toString(),
        message,
      );
    } catch (e) {
      debugPrint('保存通话记录失败: $e');
    }

    // 延迟返回
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String avatar = widget.userData['head'] ?? '';
    final String nickname = widget.userData['name'] ?? 
                          widget.userData['nickname'] ?? 
                          widget.userData['userName'] ?? 
                          '未知用户';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片
          Image.asset(
            'assets/images/head/$avatar',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.grey[900]);
            },
          ),
          // 暗色遮罩
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          // 内容
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 顶部用户信息
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      // 头像
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'assets/images/head/$avatar',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[600],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 昵称
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 状态
                      Text(
                        _callStatus + _dots,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // 底部按钮
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 挂断按钮
                      GestureDetector(
                        onTap: _isCallEnded ? null : _handleHangup,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 