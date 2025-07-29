import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/block_service.dart';
import 'feed_detail_screen.dart';
import 'user_detail_screen.dart';
import 'dart:async';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _feeds = [];
  bool _isLoading = true;
  bool _hasInitialized = false;
  StreamSubscription<BlockEvent>? _blockEventSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFeeds();
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
    if (state == AppLifecycleState.resumed) {
      // 应用重新获得焦点时刷新数据
      _loadFeeds();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 如果已经初始化过，说明是从其他页面返回，需要刷新数据
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFeeds();
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
        _feeds.removeWhere((item) {
          final userId = item['userId']?.toString() ?? 
                        item['id']?.toString() ?? 
                        item['userData']?['id']?.toString() ?? 
                        item['user']?['id']?.toString() ?? '';
          return userId == event.userId;
        });
      } else if (event.type == BlockEventType.unblocked) {
        // 解除拉黑时重新加载数据以还原被解除拉黑用户的内容
        _loadFeeds();
      }
    });
  }

  // 手动刷新方法，供外部调用或用户操作触发
  void refreshData() {
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/data/coredata.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      List<Map<String, dynamic>> type1List = [];
      
      for (var user in jsonData) {
        if (user['list'] != null) {
          for (var item in user['list']) {
            if (item['type'] == '1') {
              final feedItem = Map<String, dynamic>.from({
                ...Map<String, dynamic>.from(item),
                'userName': user['name'],
                'userHead': user['head'],
                'userId': user['id'],
                'userData': Map<String, dynamic>.from(user), // 保存完整的用户数据
                'likes': Random().nextInt(100) + 150, // 随机点赞数
              });
              
              type1List.add(feedItem);
            }
          }
        }
      }
      
      // 随机打乱所有动态数据
      type1List.shuffle(Random());
      
      // 拉黑过滤
      final filtered = await BlockService.filterBlockedUsers(type1List);
      
      if (mounted) {
        setState(() {
          _feeds = filtered;
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
    final double safeTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // 背景图
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/appicon/bg_moment.webp',
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
            ),
          ),
          // 在现场标题
          Positioned(
            top: safeTop,
            left: 16,
            child: Container(
              width: 88,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景图片
                  Image.asset(
                    'assets/images/appicon/icon_moment_tab.webp',
                    width: 88,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  // 文字
                  const Text(
                    '在现场',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 
          Positioned(
            top: safeTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: _feeds.length,
                itemBuilder: (context, index) {
                  final feed = _feeds[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedDetailScreen(feed: feed),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // 不要有margin/padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: AspectRatio(
                              aspectRatio: 166/221,
                              child: Image.asset(
                                'assets/images/iconImg/${feed['images'][0]}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          // 标题与内容区
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Text(
                              feed['title'] ?? '',
                              style: const TextStyle(fontSize: 15, color: Color(0xFF171717), fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailScreen(
                                          user: feed['userData'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/head/${feed['userHead']}',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    feed['userName'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF171717)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.thumb_up_alt_outlined, size: 18, color: Color(0xFFFFC700)),
                                const SizedBox(width: 2),
                                Text('${feed['likes']}', style: const TextStyle(fontSize: 13, color: Color(0xFF171717))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 