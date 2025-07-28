import 'package:flutter/material.dart';
import 'plaza_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'find_partner_screen.dart';
import 'publish_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey _plazaKey = GlobalKey();
  final GlobalKey _feedKey = GlobalKey();
  final GlobalKey _chatKey = GlobalKey();

  late final List<Widget> _pages = [
    PlazaScreen(key: _plazaKey),
    FeedScreen(key: _feedKey),
    const PlaceholderPage(), // 发布按钮不切换页面
    ChatListScreen(key: _chatKey),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      // 应用重新获得焦点时刷新当前页面
      debugPrint('HomeScreen: 应用恢复，刷新当前页面: $_currentIndex');
      _refreshCurrentPage();
    }
  }

  // 刷新当前页面
  void _refreshCurrentPage() {
    try {
      switch (_currentIndex) {
        case 0: // 广场
          final plazaState = _plazaKey.currentState;
          if (plazaState != null && plazaState is State) {
            (plazaState as dynamic).refreshData?.call();
          }
          break;
        case 1: // 动态
          final feedState = _feedKey.currentState;
          if (feedState != null && feedState is State) {
            (feedState as dynamic).refreshData?.call();
          }
          break;
        case 3: // 消息
          final chatState = _chatKey.currentState;
          if (chatState != null && chatState is State) {
            (chatState as dynamic).refreshData?.call();
          }
          break;
      }
    } catch (e) {
      debugPrint('刷新页面失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 49 + MediaQuery.of(context).padding.bottom, // 49 + 安全底部高度
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E5E5),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Stack(
            clipBehavior: Clip.none, // 允许子组件超出边界
            children: [
              // 文字Tab按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 广场
                  _buildTextTab(0, '广场'),
                  
                  // 动态
                  _buildTextTab(1, '动态'),
                  
                  // 占位空间（为发布按钮留出位置）
                  const SizedBox(width: 55),
                  
                  // 消息
                  _buildTextTab(3, '消息'),
                  
                  // 我的
                  _buildTextTab(4, '我的'),
                ],
              ),
              
              // 发布按钮（绝对定位）
              Positioned(
                top: -27.5, // 向上突出27.5px，让按钮完全超出Tabbar
                left: 0,
                right: 0,
                child: Center(
                  child: _buildPublishButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab(int index, String text) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16, // 16pt
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? const Color(0xFF171717) : const Color(0xFF9598AC),
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: () {
        // 显示发布选择弹框
        _showPublishOptions(context);
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF15D),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/appicon/btn_tab_add.webp',
          width: 28,
          height: 28,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.add,
              size: 28,
              color: Colors.black,
            );
          },
        ),
      ),
    );
  }

  // 显示发布选择弹框
  void _showPublishOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (BuildContext context) {
        return _buildPublishOptionsSheet();
      },
    );
  }

  // 构建发布选择弹框
  Widget _buildPublishOptionsSheet() {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 260 + bottomSafeArea,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.02, -1.0), // startPoint (0.49, 0)
          end: Alignment(0.0, 1.2),      // endPoint (0.5, 1.1)
          colors: [
            Color.fromRGBO(220, 244, 250, 1.0), // 浅蓝色
            Color.fromRGBO(237, 248, 219, 1.0), // 浅绿色
            Color.fromRGBO(255, 255, 255, 1.0), // 白色
          ],
          stops: [0.0, 0.3, 0.8], // locations
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          
          // 选项区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                // 发动态
                Expanded(
                  child: _buildSimpleOption(
                    image: 'assets/images/appicon/btn_tab_add_moment.webp',
                    title: '发动态',
                    subtitle: '分享现场瞬间',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PublishScreen(),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 60),
                
                // 找搭子
                Expanded(
                  child: _buildSimpleOption(
                    image: 'assets/images/appicon/btn_tab_add_friends.webp',
                    title: '找搭子',
                    subtitle: '热爱音乐现场组',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FindPartnerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // 关闭按钮
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 60,
              height: 60,
              margin: EdgeInsets.only(bottom: 20 + bottomSafeArea),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF15D),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              child: Image.asset(
                'assets/images/appicon/btn_tab_close.webp',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.close,
                    size: 24,
                    color: Colors.black,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建简化的发布选项
  Widget _buildSimpleOption({
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // 图标
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                image,
                width: 78,
                height: 78,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.add,
                    size: 78,
                    color: Colors.black,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 副标题
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9598AC),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '占位页面',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

 