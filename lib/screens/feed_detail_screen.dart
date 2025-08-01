import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_screen.dart';
import 'user_detail_screen.dart';
import 'image_viewer_screen.dart';

class FeedDetailScreen extends StatefulWidget {
  final Map<String, dynamic> feed;
  const FeedDetailScreen({super.key, required this.feed});

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isLiked = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<Color?> _likeColorAnimation;
  late AnimationController _plusOneAnimationController;
  late Animation<double> _plusOneOpacityAnimation;
  late Animation<Offset> _plusOnePositionAnimation;
  bool _showPlusOne = false;

  @override
  void initState() {
    super.initState();
    _initializeLikeStatus();
    _setupAnimations();
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _plusOneAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _likeColorAnimation = ColorTween(
      begin: const Color(0xFF9598AC),
      end: const Color(0xFFFFE44D),
    ).animate(_likeAnimationController);

    // +1动画控制器
    _plusOneAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _plusOneOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _plusOneAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _plusOnePositionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -3),
    ).animate(CurvedAnimation(
      parent: _plusOneAnimationController,
      curve: Curves.easeOut,
    ));
  }

  String _getFeedId() {
    // 使用多个字段生成唯一ID
    final title = widget.feed['title']?.toString() ?? '';
    final userName = widget.feed['userName']?.toString() ?? '';
    final time = widget.feed['time']?.toString() ?? '';
    return '${title}_${userName}_$time'.hashCode.toString();
  }

  Future<void> _initializeLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final feedId = _getFeedId();
    final isLiked = prefs.getBool('liked_$feedId') ?? false;
    
    setState(() {
      _isLiked = isLiked;
      if (_isLiked) {
        _likeAnimationController.value = 1.0;
      }
    });
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final feedId = _getFeedId();
    
    setState(() {
      _isLiked = !_isLiked;
    });

    // 保存点赞状态
    await prefs.setBool('liked_$feedId', _isLiked);

    // 播放动画
    if (_isLiked) {
      // 点赞动画
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
      
      // +1动画
      setState(() {
        _showPlusOne = true;
      });
      _plusOneAnimationController.forward().then((_) {
        setState(() {
          _showPlusOne = false;
        });
        _plusOneAnimationController.reset();
      });
    } else {
      _likeAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.feed['images'] as List<dynamic>?)?.cast<String>() ?? [];
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageHeight = screenWidth * 496 / 375;
    final double safeTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图片轮播（不在SafeArea内，直接从顶部展示）
          Stack(
            children: [
              SizedBox(
                width: screenWidth,
                height: imageHeight,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, idx) {
                    return GestureDetector(
                      onTap: () {
                        // 添加验证和调试信息
                        debugPrint('Opening ImageViewerScreen with ${images.length} images');
                        debugPrint('Images: $images');
                        
                        if (images.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('没有可查看的图片'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              images: images,
                              initialIndex: idx,
                              imageBasePath: 'assets/images/iconImg/',
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/iconImg/${images[idx]}',
                        width: screenWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Feed image load error: $error');
                          return Container(
                            width: screenWidth,
                            height: imageHeight,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '图片加载失败',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // 左上返回按钮
              Positioned(
                top: safeTop + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // 右上举报按钮
              Positioned(
                top: safeTop + 8,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportScreen(
                          data: widget.feed,
                          reportType: 'feed',
                          title: '举报动态',
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 图片指示器
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentIndex ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                ),
            ],
          ),
          // 详情区
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户信息区
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // 使用feed中的完整用户数据
                            if (widget.feed['userData'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailScreen(
                                    user: widget.feed['userData'],
                                  ),
                                ),
                              );
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/head/${widget.feed['userHead']}',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                widget.feed['userName'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF171717)),
                              ),
                              const SizedBox(width: 8),
                              // 性格标签图片
                              _buildPersonalityIcon(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 内容标题
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      widget.feed['title'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF171717)),
                    ),
                  ),
                  // 正文内容
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      widget.feed['content'] ?? '',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF171717)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityIcon() {
    // 获取用户性格信息，优先从userData中获取，否则从feed中获取
    String? personality;
    if (widget.feed['userData'] != null && widget.feed['userData']['personality'] != null) {
      personality = widget.feed['userData']['personality'];
    } else if (widget.feed['personality'] != null) {
      personality = widget.feed['personality'];
    }

    if (personality?.isNotEmpty == true) {
      return Image.asset(
        'assets/images/appicon/$personality',
        height: 16,
        errorBuilder: (context, error, stackTrace) {
          // 如果加载失败，默认显示i人图标
          return Image.asset(
            'assets/images/appicon/icon_i.webp',
            height: 16,
          );
        },
      );
    } else {
      // 如果没有性格信息，默认显示i人图标
      return Image.asset(
        'assets/images/appicon/icon_i.webp',
        height: 16,
      );
    }
  }
} 