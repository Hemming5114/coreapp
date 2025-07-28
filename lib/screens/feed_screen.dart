import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/block_service.dart';
import 'feed_detail_screen.dart';
import 'user_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _feeds = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFeeds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 应用重新获得焦点时刷新数据
      debugPrint('FeedScreen: 应用恢复，开始刷新数据');
      _loadFeeds();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在首次加载时刷新，避免过度刷新
    if (_feeds.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('FeedScreen: 首次加载数据');
          _loadFeeds();
        }
      });
    }
  }

  // 手动刷新方法，供外部调用或用户操作触发
  void refreshData() {
    debugPrint('FeedScreen: 手动刷新数据');
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    if (!mounted) return;
    
    debugPrint('FeedScreen: 开始加载数据');
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
            
            debugPrint('FeedScreen: 构建数据项 - userId: ${user['id']}, userName: ${user['name']}, feedTitle: ${item['title']}');
            type1List.add(feedItem);
          }
        }
      }
    }
    type1List.shuffle(Random());
    final selected = type1List.take(10).toList();
    selected.sort((a, b) => DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])));
    
    debugPrint('FeedScreen: 原始数据数量: ${selected.length}');
    
    // 拉黑过滤
    final filtered = await BlockService.filterBlockedUsers(selected);
    
    debugPrint('FeedScreen: 过滤后数据数量: ${filtered.length}');
    
    if (mounted) {
      setState(() {
        _feeds = filtered;
      });
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
            child: SizedBox(
              height: 44,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 56,
                      height: 8,
                      color: const Color(0xFFFFE44D),
                    ),
                  ),
                  const Text(
                    '在现场',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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