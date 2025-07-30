import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'plaza_detail_screen.dart';
import 'user_detail_screen.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/block_service.dart';
import 'chat_detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

class PlazaScreen extends StatefulWidget {
  const PlazaScreen({super.key});

  @override
  State<PlazaScreen> createState() => _PlazaScreenState();
}

class _PlazaScreenState extends State<PlazaScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  bool _hasInitialized = false;
  StreamSubscription<BlockEvent>? _blockEventSubscription;
  final List<Color> _cardColors = [
    const Color(0xFFFFC39E), // 浅橙色
    const Color(0xFFFFE688), // 浅黄色
    const Color(0xFFF0E9FE), // 浅紫色
    const Color(0xFFFFEDEA), // 浅粉色
    const Color(0xFFBDE6FF), // 浅蓝色
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEvents();
    _listenToBlockEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blockEventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 如果已经初始化过，说明是从其他页面返回，需要刷新数据
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('PlazaScreen: 首次加载数据');
          _loadEvents();
        }
      });
    }
  }

  // 监听拉黑事件
  void _listenToBlockEvents() {
    _blockEventSubscription = BlockService.blockEventStream.listen((event) {
      if (mounted) {
        _handleBlockEvent(event);
      }
    });
  }

  // 处理拉黑事件
  void _handleBlockEvent(BlockEvent event) {
    setState(() {
      if (event.type == BlockEventType.blocked) {
        // 立即从列表中移除被拉黑用户的数据
        _events.removeWhere((item) {
          final userId = item['userId']?.toString() ?? 
                        item['id']?.toString() ?? 
                        item['userData']?['id']?.toString() ?? 
                        item['user']?['id']?.toString() ?? '';
          return userId == event.userId;
        });
      } else if (event.type == BlockEventType.unblocked) {
        // 解除拉黑时重新加载数据以还原被解除拉黑用户的内容
        _loadEvents();
      }
    });
  }

  // 公共刷新方法，供外部调用
  void refresh() {
    _loadEvents();
  }

  // 手动刷新方法，供外部调用或用户操作触发
  void refreshData() {
    debugPrint('PlazaScreen: 手动刷新数据');
    _loadEvents();
  }

  // 处理立即结伴点击事件
  Future<void> _handleJoinEvent(Map<String, dynamic> event) async {
    try {
      // 获取活动发布者信息
      final userData = Map<String, dynamic>.from(event['userData'] ?? {});
      final String userId = userData['id']?.toString() ?? '';
      
      if (userId.isEmpty) {
        throw Exception('用户信息不完整');
      }

      // 检查是否已经存在聊天记录
      final existingChats = await ChatService.getChats();
      final existingChat = existingChats.firstWhere(
        (chat) => chat['userId'] == userId,
        orElse: () => <String, dynamic>{},
      );

      if (existingChat.isNotEmpty) {
        // 已经有聊天记录，直接进入聊天详情
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                userData: userData,
              ),
            ),
          );
        }
        return;
      }

      // 没有聊天记录，生成打招呼文案
      // 显示加载状态
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFE44D),
          ),
        ),
      );

      // 获取活动信息用于生成打招呼文案
      final String eventTitle = event['title'] ?? '';
      final String venue = event['venue'] ?? '';
      final String eventDate = event['time'] ?? '';
      
      // 构建AI请求内容
      final String prompt = '''
请为一个音乐现场活动生成一个20-50字的打招呼文案。
活动信息：
- 活动名称：$eventTitle
- 演出场地：$venue
- 演出时间：$eventDate

要求：
1. 文案要热情友好，体现对音乐的热爱
2. 自然地表达想要一起去看演出的意愿
3. 字数控制在20-50字之间
4. 语气轻松自然，不要太正式
''';

      // 调用AI生成打招呼文案
      final greetingMessage = await ApiService.sendMessage(prompt);
      
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (greetingMessage != null && greetingMessage.isNotEmpty) {
        // 创建聊天会话并发送打招呼消息
        await ChatService.createChat(userData, initialMessage: greetingMessage);
        
        if (mounted) {
          // 进入聊天详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                userData: userData,
              ),
            ),
          );
        }
      } else {
        throw Exception('生成打招呼文案失败');
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('进入聊天失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('立即结伴失败: $e');
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/data/coredata.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      List<Map<String, dynamic>> type2List = [];
      
      for (var user in jsonData) {
        if (user['list'] != null) {
          for (var item in user['list']) {
            if (item['type'] == '2') {
              final eventItem = Map<String, dynamic>.from({
                ...Map<String, dynamic>.from(item),
                'userName': user['name'],
                'userHead': user['head'],
                'userId': user['id'],
                'userData': Map<String, dynamic>.from(user), // 保存完整的用户数据
              });
              
              type2List.add(eventItem);
            }
          }
        }
      }
      
      // 随机打乱
      type2List.shuffle(Random());
      final selected = type2List.take(20).toList();
      
      // 拉黑过滤
      final filtered = await BlockService.filterBlockedUsers(selected);
      
      if (mounted) {
        setState(() {
          _events = filtered;
          _isLoading = false;
          _hasInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    return Scaffold(
      body: Stack(
        children: [
          // 固定Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/appicon/img_square_banner.webp'),
                  fit: BoxFit.cover,
                ),
              ),
                              child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
            ),
          ),
          
          // 渐变背景容器
          Positioned(
            top: 188, // 200 - 12
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.44, 0.01),
                  end: Alignment(0.49, 1.12),
                  colors: [
                    Color(0xFFDCF4FA),
                    Color(0xFFEDF8DB),
                    Color(0xFFF7F8FA),
                  ],
                  stops: [0.0, 0.3, 0.8],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          
          // 滚动内容
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            bottom: 0,
            child: RefreshIndicator(
              onRefresh: _loadEvents,
              color: const Color(0xFF007AFF), // iOS蓝色
              backgroundColor: Colors.white,
              strokeWidth: 2.5,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  final cardColor = _cardColors[index % _cardColors.length];
                  return _buildEventCard(event, cardColor, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, Color cardColor, int index) {
    // 颜色循环规则
    final List<Color> bgColors = [
      const Color(0xFFFFC39E), // 橙
      const Color(0xFFFFE688), // 黄
      const Color(0xFFBDE6FF), // 蓝
    ];
    final List<Color> gradientEndColors = [
      const Color.fromRGBO(255, 229, 216, 1), // 橙信息卡渐变终点
      const Color.fromRGBO(255, 247, 216, 1), // 黄信息卡渐变终点
      const Color.fromRGBO(189, 230, 255, 1), // 蓝信息卡渐变终点
    ];
    final bgColor = bgColors[index % 3];
    final gradientEndColor = gradientEndColors[index % 3];

    final isFull = event['topic'] == '已集齐';
    final remainingCount = event['topic'] == '找搭子' ? '还差1人' : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlazaDetailScreen(event: event, cardColor: bgColor),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        height: 186,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 信息卡内容区（白底+渐变+内容）
            Padding(
              padding: const EdgeInsets.all(0),
              child: SizedBox(
                height: 143,
                child: Stack(
                  children: [
                    // 白色底层
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // 渐变层（从上往下）
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            gradientEndColor,
                            const Color(0x00FFFFFF), // 下
                          ],
                          stops: [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    // 内容
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图片
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/iconImg/${event['images'][0]}',
                              width: 96,
                              height: 127,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 96,
                                  height: 127,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 右侧内容
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题
                              Padding(
                                padding: const EdgeInsets.only(top: 8, right: 8), // 标题右边间距8
                                child: Text(
                                  event['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF171717),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 9),
                              // 主题
                              _buildInfoRow(
                                'assets/images/appicon/icon_square_topic.webp',
                                event['topic'] ?? '找搭子',
                              ),
                              const SizedBox(height: 6),
                              // 时间
                              _buildInfoRow(
                                'assets/images/appicon/icon_square_time.webp',
                                event['time'] ?? '',
                              ),
                              const SizedBox(height: 6),
                              // 集结地
                              _buildInfoRow(
                                'assets/images/appicon/icon_square_address.webp',
                                event['location'] ?? '',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 底部区域（无白色背景）
            Container(
              height: 43,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // 还差XX/已集齐
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailScreen(
                                      user: event['userData'],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/head/${event['userHead']}',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (!isFull)
                              Positioned(
                                left: 16, // 头像宽24，重叠-8
                                child: Image.asset(
                                  'assets/images/appicon/btn_square_add.webp',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isFull) ...[
                        const SizedBox(width: 12), // 头像24，+号重叠8，剩余12
                        Text(
                          remainingCount,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF171717),
                          ),
                        ),
                      ],
                      if (isFull) ...[
                        const SizedBox(width: 8),
                        Text(
                          '已集齐',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF171717),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // 立即结伴按钮
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 76,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () => _handleJoinEvent(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF171717),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(76, 30),
                          maximumSize: const Size(76, 30),
                        ),
                        child: const Text(
                          '立即结伴',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String iconPath, String text) {
    return Row(
      children: [
        Image.asset(
          iconPath,
          width: 16,
          height: 16,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.info,
              size: 16,
              color: Colors.grey[600],
            );
          },
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 