import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/keychain_service.dart';
import '../services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  final UserModel? userData;
  
  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _singerController = TextEditingController();
  final TextEditingController _songController = TextEditingController();
  
  String _selectedPersonality = 'icon_i.webp'; // 默认i人
  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.userData != null) {
      _nicknameController.text = widget.userData!.name;
      _selectedPersonality = widget.userData!.personality;
      _singerController.text = widget.userData!.lovesinger ?? '';
      _songController.text = widget.userData!.lovesong ?? '';
    }
    
    // 监听输入变化
    _nicknameController.addListener(_onDataChanged);
    _singerController.addListener(_onDataChanged);
    _songController.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _singerController.dispose();
    _songController.dispose();
    super.dispose();
  }

  // 检查是否可以保存
  bool get _canSave {
    return _nicknameController.text.trim().isNotEmpty && _hasChanges;
  }

  // 选择头像
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _hasChanges = true;
      });
    }
  }

  // 本地黑名单词汇
  static const List<String> _blacklist = [
    'fuck', 'shit', 'bitch', 'damn', 'hell', 'ass', 'bastard', 'crap',
    '傻逼', '草泥马', '操', '妈的', '卧槽', 'shit', '靠', '艹', '日',
    '习近平', '毛泽东', '共产党', '台独', '港独', '法轮功',
    '黄色', '色情', '赌博', '毒品', '暴力', '恐怖',
  ];

  // 本地黑名单检测
  bool _containsBlacklistedWords(String text) {
    final lowerText = text.toLowerCase();
    for (final word in _blacklist) {
      if (lowerText.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  // 验证昵称合规性
  Future<bool> _validateNickname(String nickname) async {
    // 1. 先进行本地黑名单检测
    if (_containsBlacklistedWords(nickname)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称包含不当词汇，请重新输入')),
        );
      }
      return false;
    }

    // 2. 再进行AI检测
    setState(() {
      _isValidating = true;
    });
    
    try {
      final response = await ApiService.sendMessage(
        '请判断这个昵称是否包含明显的不当内容："$nickname"。'
        '检查标准：只需要检查是否包含明显的涉黄、涉黑、政治敏感等严重不当内容。'
        '对于正常的音乐相关昵称、网络用名等应该放行。'
        '如果昵称正常，请只回复"通过"。'
        '如果包含明显不当内容，请回复"拒绝：具体原因"。'
      );
      
      debugPrint('昵称验证响应: $response');
      
      // 严格检查回复是否为"通过"
      if (response != null && response.trim() == '通过') {
        return true;
      }
      
      // 显示不合规原因
      if (mounted) {
        final reason = response?.startsWith('拒绝：') == true 
            ? response!.substring(3) 
            : '昵称可能包含不当内容，请重新输入';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
      }
      return false;
    } catch (e) {
      debugPrint('验证昵称失败: $e');
      // 网络错误时，仍然进行本地检测
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后重试')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  // 验证歌手歌曲真实性
  Future<bool> _validateArtistAndSong(String singer, String song) async {
    if (singer.isEmpty && song.isEmpty) return true;
    
    setState(() {
      _isValidating = true;
    });
    
    try {
      String query = '';
      if (singer.isNotEmpty && song.isNotEmpty) {
        query = '请确认歌手"$singer"和歌曲"$song"是否真实存在。';
      } else if (singer.isNotEmpty) {
        query = '请确认歌手"$singer"是否真实存在。';
      } else if (song.isNotEmpty) {
        query = '请确认歌曲"$song"是否真实存在。';
      }
      
      query += '如果确认存在请回复"存在"，如果不确定请回复"不确定"。';
      
      final response = await ApiService.sendMessage(query);
      
      if (response != null && response.contains('存在')) {
        return true;
      } else if (response != null && response.contains('不确定')) {
        // 弹框询问用户
        return await _showConfirmDialog();
      }
      
      return false;
    } catch (e) {
      debugPrint('验证歌手歌曲失败: $e');
      return await _showConfirmDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  // 显示确认对话框
  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('无法确认您填写的歌手或歌曲信息，是否仍要保存？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 保存头像到本地
  Future<String?> _saveAvatarToLocal() async {
    if (_selectedImage == null) return null;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      
      // 创建头像目录
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      
      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(_selectedImage!.path);
      final fileName = 'avatar_$timestamp$extension';
      final localPath = '${avatarDir.path}/$fileName';
      
      // 复制文件到本地
      await _selectedImage!.copy(localPath);
      
      return fileName; // 返回文件名用于存储
    } catch (e) {
      debugPrint('保存头像失败: $e');
      return null;
    }
  }

  // 保存数据
  Future<void> _saveProfile() async {
    if (!_canSave) return;
    
    // 收起键盘
    FocusScope.of(context).unfocus();
    
    setState(() { _isLoading = true; });
    
    try {
      // 1. 验证昵称合规性
      if (!await _validateNickname(_nicknameController.text.trim())) {
        setState(() { _isLoading = false; });
        return;
      }
      
      // 2. 验证歌手歌曲真实性（只有当有内容时才验证）
      final singer = _singerController.text.trim();
      final song = _songController.text.trim();
      
      if (singer.isNotEmpty || song.isNotEmpty) {
        if (!await _validateArtistAndSong(singer, song)) {
          setState(() { _isLoading = false; });
          return;
        }
      }
      
      // 3. 保存头像到本地
      String? avatarFileName;
      if (_selectedImage != null) {
        avatarFileName = await _saveAvatarToLocal();
        if (avatarFileName == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('头像保存失败，请重试')),
            );
          }
          setState(() { _isLoading = false; });
          return;
        }
      }
      
      // 4. 保存数据到keychain
      final updatedUser = UserModel(
        name: _nicknameController.text.trim(),
        userId: widget.userData?.userId ?? 0,
        coins: widget.userData?.coins ?? 0,
        membershipExpiry: widget.userData?.membershipExpiry ?? DateTime.now(),
        personality: _selectedPersonality,
        head: avatarFileName ?? widget.userData?.head ?? 'user_head_1.webp', // 使用新头像或保持原头像
        originalHead: widget.userData?.originalHead ?? widget.userData?.head ?? 'user_head_1.webp', // 保持原始头像不变
        lovesinger: singer.isEmpty ? null : singer,
        lovesong: song.isEmpty ? null : song,
        followCount: widget.userData?.followCount ?? 0,
        fansCount: widget.userData?.fansCount ?? 0,
      );
      
      await KeychainService.saveUserInfo(updatedUser.toJson());
      
      // 5. 显示提示信息
      if (mounted) {
        String message = '保存成功！';
        if (avatarFileName != null) {
          message = '数据已提交审核，头像审核中，审核成功前仅自己可见';
        } else if (singer.isNotEmpty || song.isNotEmpty) {
          message = '数据已提交审核，审核成功前仅自己可见';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        
        // 返回上一页
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 构建头像widget（与profile_screen.dart保持一致）
  Widget _buildAvatarWidget({required double size}) {
    if (widget.userData?.head == null) {
      return _buildDefaultAvatar(size);
    }

    final head = widget.userData!.head;
    
    // 检查是否是自定义头像（包含avatar_前缀的本地文件）
    if (head.startsWith('avatar_')) {
      return FutureBuilder<File?>(
        future: _getLocalAvatarFile(head),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              children: [
                Image.file(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 如果自定义头像加载失败，显示原始头像
                    return _buildOriginalAvatar(size);
                  },
                ),
                // 审核中标识
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '审核中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
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

  // 构建原始头像
  Widget _buildOriginalAvatar(double size) {
    String? originalHead = widget.userData?.originalHead;
    
    // 如果originalHead为空或者是自定义头像文件名，则回退到head字段
    if (originalHead == null || originalHead.isEmpty || originalHead.startsWith('avatar_')) {
      originalHead = widget.userData?.head;
    }
    
    // 如果head也是自定义头像文件名或为空，则使用默认头像
    if (originalHead == null || originalHead.isEmpty || originalHead.startsWith('avatar_')) {
      return _buildDefaultAvatar(size);
    }
    
    return Image.asset(
      'assets/images/head/$originalHead',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultAvatar(size);
      },
    );
  }

  // 构建默认头像
  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size * 0.4,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildCurrentAvatar() {
    return ClipOval(
      child: _buildAvatarWidget(size: 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    
    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
          body: GestureDetector(
            onTap: () {
              // 点击空白收起键盘
              FocusScope.of(context).unfocus();
            },
            child: Column(
        children: [
          // 顶部导航栏
          Container(
            height: 44 + safeTop,
            padding: EdgeInsets.only(top: safeTop),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                const Expanded(
                  child: Text(
                    '编辑资料',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // 平衡左边的返回按钮
              ],
            ),
          ),
          
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像选择
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _buildCurrentAvatar(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '请上传头像',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // 性格选择
                  const Text(
                    '你是什么性格的人',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPersonality = 'icon_i.webp';
                            _hasChanges = true;
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedPersonality == 'icon_i.webp'
                                ? const Color(0xFFFCF15D)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPersonality == 'icon_i.webp'
                                  ? const Color(0xFFE6D93B)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'i 人',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPersonality = 'icon_e.webp';
                            _hasChanges = true;
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedPersonality == 'icon_e.webp'
                                ? const Color(0xFFFCF15D)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPersonality == 'icon_e.webp'
                                  ? const Color(0xFFE6D93B)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'e 人',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 昵称输入
                  const Text(
                    '大家应该怎么称呼你',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: '取一个好听的昵称吧～',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      counterText: '', // 隐藏字符计数器
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 喜欢的歌手
                  const Text(
                    '我最喜欢的歌手',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _singerController,
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: '你喜欢的歌手是？',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      counterText: '', // 隐藏字符计数器
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 喜欢的歌曲
                  const Text(
                    '我最喜欢的歌曲',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _songController,
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: '你喜欢的歌曲是？',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      counterText: '', // 隐藏字符计数器
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // 底部保存按钮
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSave && !_isValidating && !_isLoading ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? const Color(0xFF2C2C2C) : Colors.grey[300],
                    foregroundColor: _canSave ? Colors.white : Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
            ),
      ),
        ),
        
        // Loading遮罩层
        if (_isValidating || _isLoading)
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
    );
  }
} 