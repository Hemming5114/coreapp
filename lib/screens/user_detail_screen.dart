import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/chat_service.dart';
import '../services/block_service.dart';
import '../widgets/user_music_preferences_widget.dart';
import 'feed_detail_screen.dart';
import 'feed_report_screen.dart';
import 'chat_detail_screen.dart';
import 'video_call_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  bool _isFollowing = false;
  int _followersCount = 0;
  bool _loading = true;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() { _loading = true; });
    
    try {
      // 检查关注状态
      final isFollowing = await FollowService.isFollowing(widget.user['id'].toString());
      
      // 获取粉丝数
      final followersCount = await FollowService.getUserFollowersCount(
        widget.user['id'].toString(),
        widget.user['fans'] ?? 0,
      );
      
      setState(() {
        _isFollowing = isFollowing;
        _followersCount = followersCount;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _toggleFollow() async {
    if (_loading) return;
    
    setState(() { _loading = true; });
    
    try {
      final userId = widget.user['id'].toString();
      
      if (_isFollowing) {
        // 取消关注
        await FollowService.unfollowUser(userId);
        await FollowService.decreaseFollowers(userId);
        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
      } else {
        // 关注 - 保存完整用户数据
        await FollowService.followUserWithData(widget.user);
        await FollowService.increaseFollowers(userId);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  // 举报用户
  void _reportUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedReportScreen(
          feed: widget.user,
          reportType: 'user',
        ),
      ),
    );
  }

  // 拉黑用户
  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('拉黑用户'),
          content: Text('确定要拉黑用户 "${widget.user['name'] ?? '该用户'}" 吗？拉黑后将不再看到此用户的内容。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // 执行拉黑操作
        final success = await BlockService.blockUser(widget.user);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已拉黑用户 "${widget.user['name'] ?? '该用户'}"'),
                backgroundColor: Colors.orange,
              ),
            );
            // 拉黑后返回到一级页面（聊天列表页面）
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('拉黑失败，请重试'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('拉黑用户失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('拉黑失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 开始聊天
  Future<void> _startChat() async {
    try {
      // 确保类型转换正确
      final userData = Map<String, dynamic>.from(widget.user);
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

      if (existingChat.isEmpty) {
        // 没有聊天记录，创建新的空聊天会话
        await ChatService.createChat(userData);
      }
      
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
    } catch (e) {
      debugPrint('开始聊天失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('开始聊天失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double safeTop = MediaQuery.of(context).padding.top;
    final double avatarHeight = screenWidth * (375 / 375); // 375:375 比例
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // 主要内容区域
          Expanded(
            child: Stack(
              children: [
                // 用户头像背景区域
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: avatarHeight,
                  child: Stack(
                    children: [
                      // 用户头像
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                        ),
                        child: Image.asset(
                          'assets/images/head/${widget.user['head']}',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.fill,
                        ),
                      ),
                      // 渐变遮罩
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                          ),
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
                    ],
                  ),
                ),
                
                // 顶部导航栏
                Positioned(
                  top: safeTop,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        // 举报按钮
                        IconButton(
                          icon: const Icon(Icons.report_outlined, color: Colors.white, size: 24),
                          onPressed: _reportUser,
                        ),
                        // 拉黑按钮
                        IconButton(
                          icon: const Icon(Icons.block_outlined, color: Colors.white, size: 24),
                          onPressed: _blockUser,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 用户信息卡片
                Positioned(
                  top: avatarHeight - 106, // 距离头像底部-106
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 166,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 第一行：昵称、性别、性格
                              Row(
                                children: [
                                  // 昵称
                                  Text(
                                    widget.user['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF171717),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 性别图标
                                  Image.asset(
                                    widget.user['gender'] == 'male' 
                                      ? 'assets/images/appicon/icon_boy.webp'
                                      : 'assets/images/appicon/icon_girl.webp',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 0),
                                  // 性格图标
                                  Image.asset(
                                    'assets/images/appicon/${widget.user['personality']}',
                                    width: 29,
                                    height: 16,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // 关注和粉丝数
                              Text(
                                '${widget.user['follow'] ?? 0} 关注 $_followersCount 粉丝',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9598AC),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // 最喜欢的歌手和歌曲
                              UserMusicPreferencesWidget(
                                loveSinger: widget.user['lovesinger'],
                                loveSong: widget.user['lovesong'],
                                isOwn: false,
                              ),
                            ],
                          ),
                        ),
                        // 操作按钮区域 - 放在右上角
                        Positioned(
                          top: 12,
                          right: 16,
                          child: SizedBox(
                            width: 60,
                            height: 28,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing ? Colors.grey[300] : const Color(0xFFFFE44D),
                                foregroundColor: const Color(0xFF171717),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                _isFollowing ? '已关注' : '关注',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Tab内容区域
                Positioned(
                  top: avatarHeight - 106 + 166 + 10, // 头像底部-106 + 卡片高度166 + 间距10
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Tab切换
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // 动态Tab
                              GestureDetector(
                                onTap: () {
                                  _tabController.animateTo(0);
                                },
                                child: Container(
                                  width: 44,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 背景图片
                                      if (_currentTabIndex == 0)
                                        Image.asset(
                                          'assets/images/appicon/icon_moment_tab.webp',
                                          width: 44,
                                          height: 30,
                                          fit: BoxFit.contain,
                                        ),
                                      // 文字
                                      Text(
                                        '动态',
                                        style: TextStyle(
                                          fontSize: _currentTabIndex == 0 ? 20 : 15,
                                          fontWeight: FontWeight.w600, // Semibold
                                          color: const Color(0xFF171717),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Ta的足迹Tab
                              GestureDetector(
                                onTap: () {
                                  _tabController.animateTo(1);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 24),
                                  width: 84,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 背景图片
                                      if (_currentTabIndex == 1)
                                        Image.asset(
                                          'assets/images/appicon/icon_moment_tab.webp',
                                          width: 84,
                                          height: 30,
                                          fit: BoxFit.contain,
                                        ),
                                      // 文字
                                      Text(
                                        'Ta的足迹',
                                        style: TextStyle(
                                          fontSize: _currentTabIndex == 1 ? 20 : 15,
                                          fontWeight: FontWeight.w600, // Semibold
                                          color: const Color(0xFF171717),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Tab内容
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMomentsList(),
                              _buildFootprintsList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部按钮区域
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE0E0E0),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 聊一下按钮 - 占2/3宽度
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _startChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE44D),
                        foregroundColor: const Color(0xFF171717),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '聊一下',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 视频按钮 - 占1/3宽度
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallScreen(
                              userData: widget.user,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE44D),
                        foregroundColor: const Color(0xFF171717),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '视频',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsList() {
    final moments = widget.user['list'] as List<dynamic>? ?? [];
    final type1Moments = moments.where((moment) => moment['type'] == '1').toList();
    
    if (type1Moments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              '暂无动态',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF9598AC),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero, // 移除GridView的顶部间距
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75, // 固定宽高比
        ),
        itemCount: type1Moments.length,
        itemBuilder: (context, index) {
          final moment = type1Moments[index];
          final images = (moment['images'] as List<dynamic>?)?.cast<String>() ?? [];
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedDetailScreen(feed: {
                    ...moment,
                    'userName': widget.user['name'],
                    'userHead': widget.user['head'],
                    'userId': widget.user['id'],
                    'userData': widget.user,
                  }),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片区域 - 固定高度
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/images/iconImg/${images.isNotEmpty ? images[0] : 'icon_img_111.webp'}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // 标题区域 - 固定高度
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Text(
                        moment['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 15, 
                          color: Color(0xFF171717), 
                          fontWeight: FontWeight.w500
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFootprintsList() {
    final moments = widget.user['list'] as List<dynamic>? ?? [];
    final type2Moments = moments.where((moment) => moment['type'] == '2').toList();
    
    if (type2Moments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              '暂无足迹',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF9598AC),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: type2Moments.length,
      itemBuilder: (context, index) {
        final moment = type2Moments[index];
        final images = (moment['images'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // 生成渐变颜色
        final List<Color> gradientColors = [
          const Color(0xFFE8F5E8),
          const Color(0xFFF0F8FF),
          const Color(0xFFFFF5E8),
          const Color(0xFFF8E8FF),
          const Color(0xFFE8F8FF),
        ];
        final gradientEndColor = gradientColors[index % gradientColors.length];
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FeedDetailScreen(feed: {
                  ...moment,
                  'userName': widget.user['name'],
                  'userHead': widget.user['head'],
                  'userId': widget.user['id'],
                  'userData': widget.user,
                }),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
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
                            const Color(0x00FFFFFF), // 透明
                          ],
                          stops: const [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(12),
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
                              'assets/images/iconImg/${images.isNotEmpty ? images[0] : 'icon_img_111.webp'}',
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
                                padding: const EdgeInsets.only(top: 8, right: 8),
                                child: Text(
                                  moment['title'] ?? '',
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
                                moment['topic'] ?? '找搭子',
                              ),
                              const SizedBox(height: 6),
                              // 时间
                              _buildInfoRow(
                                'assets/images/appicon/icon_square_time.webp',
                                moment['time'] ?? '',
                              ),
                              const SizedBox(height: 6),
                              // 集结地
                              _buildInfoRow(
                                'assets/images/appicon/icon_square_address.webp',
                                moment['location'] ?? '',
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
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String iconPath, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF9598AC),
              );
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9598AC),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 