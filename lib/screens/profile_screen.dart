import 'package:flutter/material.dart';
import 'dart:io';
import 'feed_detail_screen.dart';
import '../services/keychain_service.dart';
import '../services/partner_service.dart';
import '../services/moment_service.dart';
import '../services/image_storage_service.dart';
import '../models/user_model.dart';
import '../widgets/user_music_preferences_widget.dart';
import 'edit_profile_screen.dart';
import 'publish_screen.dart';
import 'find_partner_screen.dart';
import 'settings_screen.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  UserModel? _userData;
  List<Map<String, dynamic>> _moments = [];
  List<Map<String, dynamic>> _footprints = [];

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
    try {
      // 从keychain获取用户信息
      final userInfo = await KeychainService.getUserInfo();
      
      debugPrint('ProfilePage - 从Keychain获取的用户数据: $userInfo');
      
      if (userInfo != null && userInfo.isNotEmpty) {
        final userModel = UserModel.fromJson(userInfo);
        
        // 加载找搭子数据和动态数据
        final partnerRequests = await PartnerService.getPartnerRequests();
        final moments = await MomentService.getMoments();
        
        setState(() {
          _userData = userModel;
          _moments = moments; // 显示动态数据
          _footprints = partnerRequests; // 显示找搭子数据在足迹中
        });
        debugPrint('ProfilePage - 用户数据加载成功: ${_userData?.name}');
        debugPrint('ProfilePage - 找搭子数据加载成功: ${partnerRequests.length}条');
        debugPrint('ProfilePage - 动态数据加载成功: ${moments.length}条');
      } else {
        debugPrint('ProfilePage - Keychain中没有用户数据');
        setState(() {
          _userData = null;
          _moments = [];
          _footprints = [];
        });
      }
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
      setState(() {
        _userData = null;
        _moments = [];
        _footprints = [];
      });
    }
  }

  // 获取图片完整路径
  Future<String> _getImagePath(String fileName) async {
    try {
      // 如果已经是完整路径，直接返回
      if (fileName.contains('/')) {
        return fileName;
      }
      
      // 如果是文件名，构建完整路径
      return await ImageStorageService.getImagePath(fileName);
    } catch (e) {
      debugPrint('获取图片路径失败: $e');
      return '';
    }
  }

  // 导航到编辑页面
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    );
    
    // 如果编辑成功，重新加载用户数据
    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          
          // 右上角按钮
          Positioned(
            top: safeTop + 10,
            right: 16,
            child: Row(
              children: [
                // 编辑个人资料按钮
                GestureDetector(
                  onTap: _navigateToEditProfile,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 设置页面入口按钮
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 个人信息卡片
          Positioned(
            top: safeTop + 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 16), // 调整top padding让昵称与头像中心对齐
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 昵称和性格标签（与头像Y轴中心对齐）
                  Padding(
                    padding: const EdgeInsets.only(left: 100), // 头像右边114px，顶部位置已通过卡片padding调整
                    child: Row(
                      children: [
                        Text(
                          (_userData?.name?.isNotEmpty ?? false) 
                              ? _userData!.name 
                              : '请设置昵称',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: (_userData?.name?.isNotEmpty ?? false) 
                                ? Colors.black 
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 性格标签图片
                        (_userData?.personality?.isNotEmpty ?? false)
                            ? Image.asset(
                                'assets/images/appicon/${_userData!.personality}',
                                height: 16,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/appicon/icon_i.webp',
                                    height: 16,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/appicon/icon_i.webp',
                                height: 16,
                              ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30), // 头像底部62px - 昵称位置17px + 需要的间距14px = 59px
                  
                  // 我最喜欢的歌手和歌曲
                  UserMusicPreferencesWidget(
                    loveSinger: _userData?.lovesinger,
                    loveSong: _userData?.lovesong,
                    isOwn: true,
                    onTap: _navigateToEditProfile,
                  ),
                ],
              ),
            ),
          ),
          
          // 头像 - 超出卡片顶部显示，靠左12px
          Positioned(
            top: safeTop + 60 - 28, // 卡片顶部 - 28px
            left: 16 + 12, // 卡片左边距 + 12px
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
                child: _buildAvatarWidget(size: 90),
            ),
          ),
          

          
          // Tab内容区域
          Positioned(
            top: safeTop + 60 + 160 + 10, // 个人信息卡片位置 + 卡片高度 + 20px间距
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
                    padding: const EdgeInsets.only(left: 16, top: 2, right: 16),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 背景图片
                                if (_currentTabIndex == 0)
                                  Image.asset(
                                    'assets/images/appicon/icon_moment_tab.webp',
                                    width: 44,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                // 文字
                                Text(
                                  '动态',
                                  style: TextStyle(
                                    fontSize: _currentTabIndex == 0 ? 20 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF171717),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 我的足迹Tab
                        GestureDetector(
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 24),
                            width: 84,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 背景图片
                                if (_currentTabIndex == 1)
                                  Image.asset(
                                    'assets/images/appicon/icon_moment_tab.webp',
                                    width: 84,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                // 文字
                                Text(
                                  '我的足迹',
                                  style: TextStyle(
                                    fontSize: _currentTabIndex == 1 ? 20 : 15,
                                    fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMomentsList() {
    if (_moments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有发布过哦～',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PublishScreen(),
                  ),
                );
                // 如果发布成功，重新加载数据
                if (result == true || mounted) {
                  _loadUserData();
                }
              },
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '去发布',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _moments.length,
        itemBuilder: (context, index) {
          final moment = _moments[index];
          final images = (moment['images'] as List<dynamic>?)?.cast<String>() ?? [];
          
          return GestureDetector(
            onTap: () {
              // 点击卡片查看详情（可以添加详情页面）
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片区域
                  Expanded(
                    flex: 4,
                        child: Stack(
                          children: [
                            ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                              child: images.isNotEmpty
                                  ? FutureBuilder<String>(
                                      future: _getImagePath(images[0]),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          return Image.file(
                                            File(snapshot.data!),
                        width: double.infinity,
                                            height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                                              width: double.infinity,
                                              height: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                                          );
                                        }
                                        return Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                    ),
                            ),
                            // 审核状态标识
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () => _showAuditStatusDialog(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '审核中',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
                  // 标题区域
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
                  // 编辑按钮
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _editMoment(moment),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Color(0xFF666666),
                        ),
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
    if (_footprints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '你还没有发布找搭子哦～',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FindPartnerScreen(),
                  ),
                );
                // 如果发布成功，重新加载数据
                if (result == true || mounted) {
                  _loadUserData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '去发布',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _footprints.length,
        itemBuilder: (context, index) {
          final partner = _footprints[index];
          
          // 颜色循环规则
          final List<Color> gradientEndColors = [
            const Color.fromRGBO(255, 229, 216, 0.6), // 橙信息卡渐变终点，60%透明度
            const Color.fromRGBO(255, 247, 216, 0.6), // 黄信息卡渐变终点，60%透明度
            const Color.fromRGBO(189, 230, 255, 0.6), // 蓝信息卡渐变终点，60%透明度
          ];
          final gradientColor = gradientEndColors[index % 3];
          
          return GestureDetector(
            onTap: () {
              // 点击卡片查看详情（可以添加详情页面）
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
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
                            gradientColor, // 循环颜色，60%透明度
                            const Color(0x00FFFFFF), // 完全透明
                          ],
                          stops: const [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // 内容
                    Stack(
                      children: [
                        Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                                child: partner['coverImage'] != null
                                    ? FutureBuilder<String>(
                                        future: _getImagePath(partner['coverImage']),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                            return Image.file(
                                              File(snapshot.data!),
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
                                            );
                                          }
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
                                      )
                                    : Container(
                                        width: 96,
                                        height: 127,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                              ),
                              // 审核状态标识
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _showAuditStatusDialog(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '审核中',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 右侧内容
                    Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题
                                Text(
                                  partner['venue'] ?? '演出场次',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF171717),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 9),
                          // 主题
                          _buildInfoRow(
                            'assets/images/appicon/icon_square_topic.webp',
                                  partner['theme'] ?? '找搭子',
                          ),
                          const SizedBox(height: 6),
                          // 时间
                          _buildInfoRow(
                            'assets/images/appicon/icon_square_time.webp',
                                  _formatPartnerDate(partner['date']),
                          ),
                          const SizedBox(height: 6),
                          // 集结地
                          _buildInfoRow(
                            'assets/images/appicon/icon_square_address.webp',
                                  partner['location'] ?? '',
                          ),
                        ],
                            ),
                      ),
                    ),
                  ],
                ),
                        // 编辑按钮
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _editPartnerRequest(partner),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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

  // 构建头像widget
  Widget _buildAvatarWidget({required double size}) {
    if (_userData?.head == null) {
      return _buildDefaultAvatar(size);
    }

    final head = _userData!.head;
    
    // 检查是否是自定义头像（包含avatar_前缀的本地文件）
    if (head.startsWith('avatar_')) {
      return FutureBuilder<File?>(
        future: _getLocalAvatarFile(head),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              clipBehavior: Clip.none, // 允许子组件超出边界
              children: [
                ClipOval(
                  child: Image.file(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 如果自定义头像加载失败，显示原始头像
                    return _buildOriginalAvatar(size);
                  },
                  ),
                ),
                // 审核中标识
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '审核中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // 如果自定义头像文件不存在，显示原始头像
            return _buildOriginalAvatar(size);
          }
        },
      );
    } else {
      // 使用assets头像（原始头像或其他）
      return _buildOriginalAvatar(size);
    }
  }

  // 构建原始头像
  Widget _buildOriginalAvatar(double size) {
    String? originalHead = _userData?.originalHead;
    
    // 如果originalHead为空或者是自定义头像文件名，则回退到head字段
    if (originalHead == null || originalHead.isEmpty || originalHead.startsWith('avatar_')) {
      originalHead = _userData?.head;
    }
    
    // 如果head也是自定义头像文件名或为空，则使用默认头像
    if (originalHead == null || originalHead.isEmpty || originalHead.startsWith('avatar_')) {
      return _buildDefaultAvatar(size);
    }
    
    return ClipOval(
      child: Image.asset(
      'assets/images/head/$originalHead',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultAvatar(size);
      },
      ),
    );
  }

  // 获取本地头像文件
  Future<File?> _getLocalAvatarFile(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarFile = File('${appDir.path}/avatars/$fileName');
      
      if (await avatarFile.exists()) {
        return avatarFile;
      }
      return null;
    } catch (e) {
      debugPrint('获取本地头像失败: $e');
      return null;
    }
  }

  // 构建默认头像
  Widget _buildDefaultAvatar(double size) {
    return ClipOval(
      child: Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: Colors.grey[600],
        ),
      ),
    );
  }

  // 格式化找搭子日期
  String _formatPartnerDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '未设置时间';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}年${date.month}月${date.day}日';
    } catch (e) {
      return '时间格式错误';
    }
  }

  // 显示审核状态说明弹框
  void _showAuditStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '信息审核中',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你的找搭子信息正在审核中，请耐心等待。',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• 审核通过后，信息将在广场中展示',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• 其他用户可以看到并联系你',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• 审核中的信息支持编辑修改',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '一般审核时间为1-3个工作日，感谢你的理解！',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFCF15D),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: const Text(
                '我知道了',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 编辑找搭子信息
  Future<void> _editPartnerRequest(Map<String, dynamic> partner) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FindPartnerScreen(
          editMode: true,
          editData: partner,
        ),
      ),
    );
    
    // 如果编辑成功，重新加载数据
    if (result == true) {
      _loadUserData();
    }
  }

  // 显示编辑找搭子信息弹框
  void _showEditPartnerDialog(Map<String, dynamic> partner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '编辑找搭子信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你可以修改还在审核中的找搭子信息，修改后将重新提交审核。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '演出场次：${partner['venue'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '主题：${partner['theme'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '取消',
                style: TextStyle(
                  color: Color(0xFF999999),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 跳转到编辑页面，可以传入现有数据
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('编辑功能开发中...')),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFCF15D),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                '去编辑',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
     }

  // 编辑动态信息
  Future<void> _editMoment(Map<String, dynamic> moment) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PublishScreen(
          editMode: true,
          editData: moment,
        ),
      ),
    );
    
    // 如果编辑成功，重新加载数据
    if (result == true) {
      _loadUserData();
    }
  }
  
} 