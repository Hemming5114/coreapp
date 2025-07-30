import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/moment_service.dart';
import '../services/api_service.dart';
import '../services/image_storage_service.dart';
import '../services/keychain_service.dart';
import '../models/user_model.dart';
import 'coin_recharge_screen.dart';
import 'vip_recharge_screen.dart';
import 'ai_content_generator_screen.dart';

class PublishScreen extends StatefulWidget {
  final bool editMode;
  final Map<String, dynamic>? editData;
  
  const PublishScreen({
    super.key,
    this.editMode = false,
    this.editData,
  });

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<File> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isValidating = false;
  
  // 用户数据相关
  UserModel? _userData;
  int _todayPublishCount = 0;

  @override
  void initState() {
    super.initState();
    
    // 加载用户数据
    _loadUserData();
    
    // 如果是编辑模式，填充现有数据
    if (widget.editMode && widget.editData != null) {
      _fillEditData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 填充编辑数据
  Future<void> _fillEditData() async {
    final data = widget.editData!;
    
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';
    
    // 加载图片列表（从文件名转换为完整路径）
    if (data['images'] != null && data['images'] is List) {
      List<File> validImages = [];
      for (String fileName in (data['images'] as List<dynamic>).cast<String>()) {
        try {
          final fullPath = await ImageStorageService.getImagePath(fileName);
          final file = File(fullPath);
          if (await file.exists()) {
            validImages.add(file);
          }
        } catch (e) {
          debugPrint('加载图片失败: $fileName, $e');
        }
      }
      _selectedImages = validImages;
    }
    
    setState(() {});
  }
  
  // 加载用户数据
  Future<void> _loadUserData() async {
    try {
      final userInfo = await KeychainService.getUserInfo();
      if (userInfo != null && userInfo.isNotEmpty) {
        setState(() {
          _userData = UserModel.fromJson(userInfo);
        });
        // 加载今日发布次数
        await _loadTodayPublishCount();
      }
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
    }
  }
  
  // 加载今日发布次数
  Future<void> _loadTodayPublishCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'moment_publish_count_${today.year}_${today.month}_${today.day}';
      
      final count = prefs.getInt(todayKey) ?? 0;
      setState(() {
        _todayPublishCount = count;
      });
    } catch (e) {
      debugPrint('加载今日发布次数失败: $e');
    }
  }

  // 选择图片
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 9) return;
    
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      final remainingSlots = 9 - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).toList();
      
      setState(() {
        _selectedImages.addAll(imagesToAdd.map((xfile) => File(xfile.path)));
      });
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择图片失败')),
        );
      }
    }
  }

  // 删除图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 验证表单数据
  bool _validateForm() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    // 1. 验证标题
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题')),
      );
      return false;
    }
    
    if (title.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题至少需要2个字符')),
      );
      return false;
    }
    
    if (title.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题不能超过50个字符')),
      );
      return false;
    }
    
    // 2. 验证内容
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写内容')),
      );
      return false;
    }
    
    if (content.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容至少需要5个字符')),
      );
      return false;
    }
    
    if (content.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容不能超过2000个字符')),
      );
      return false;
    }
    
    // 3. 验证内容质量
    if (_isLowQualityContent(title) || _isLowQualityContent(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有意义的内容，避免使用过多重复字符或符号')),
      );
      return false;
    }
    
    // 4. 验证是否有实质内容（文字或图片）
    if (content.length < 10 && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请添加更多文字内容或选择图片')),
      );
      return false;
    }
    
    // 5. 验证图片数量
    if (_selectedImages.length > 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能选择9张图片')),
      );
      return false;
    }
    
    return true;
  }
  
  // 检查是否为低质量内容
  bool _isLowQualityContent(String text) {
    // 检查是否全是空白字符
    if (text.replaceAll(RegExp(r'\s'), '').isEmpty) {
      return true;
    }
    
    // 检查是否有过多重复字符
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) {
      return true;
    }
    
    // 检查是否全是特殊字符
    if (RegExp(r'^[^\w\u4e00-\u9fff]*$').hasMatch(text)) {
      return true;
    }
    
    // 检查是否有有效的中文或英文内容
    final validContent = RegExp(r'[\w\u4e00-\u9fff]').allMatches(text).length;
    if (validContent < text.length * 0.3) {
      return true;
    }
    
    return false;
  }

  // 检查本地黑名单
  bool _containsBlacklistedWords(String text) {
    final blacklist = [
      '违法', '不良', '垃圾', '广告', '诈骗', '传销', '暴力', '恐怖',
      '黄色', '色情', '赌博', '毒品', '政治', '反动', '邪教', '迷信',
      '辱骂', '歧视', '仇恨', '威胁', '恶意', '虚假', '欺诈', '骗子'
    ];
    
    final lowerText = text.toLowerCase();
    for (String word in blacklist) {
      if (lowerText.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  // 验证内容合规性
  Future<bool> _validateContent() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    // 1. 先进行本地黑名单检测
    final allText = '$title $content';
    if (_containsBlacklistedWords(allText)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('内容包含不当词汇，请重新输入')),
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
        '请判断这些动态内容是否包含明显的不当内容：\n'
        '标题："$title"\n'
        '内容："$content"\n'
        '检查标准：只需要检查是否包含明显的涉黄、涉黑、政治敏感等严重不当内容。'
        '如果内容正常或者无法判断，请只回复"通过"。'
        '如果包含明显不当内容，请回复"拒绝：具体原因"。'
      );
      
      debugPrint('动态内容验证响应: $response');
      
      // 严格检查回复是否为"通过"
      if (response != null && response.trim() == '通过') {
        return true;
      }
      
      // 显示不合规原因
      if (mounted) {
        final reason = response?.startsWith('拒绝：') == true 
            ? response!.substring(3) 
            : '内容可能包含不当信息，请重新输入';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
      }
      return false;
    } catch (e) {
      debugPrint('验证内容失败: $e');
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

  // 保存数据
  Future<void> _saveData() async {
    if (!_validateForm()) return;
    
    // 收起键盘并移除焦点
    _clearFocusAndDismissKeyboard();
    
    // 等待键盘完全收起
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 检查发布限制
    final canPublish = await _checkPublishLimit();
    if (!canPublish) {
      // 如果发布被取消，确保键盘不会重新弹出
      _clearFocusAndDismissKeyboard();
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // 内容审核
      final isApproved = await _validateContent();
      
      if (!isApproved) {
        // 如果审核失败，确保键盘不会重新弹出
        _clearFocusAndDismissKeyboard();
        return;
      }
      
      // 保存图片到永久位置
      List<String> savedImagePaths = [];
      if (_selectedImages.isNotEmpty) {
        savedImagePaths = await ImageStorageService.saveImagesPermanently(_selectedImages);
      }
      
      // 构建数据
      final data = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'images': savedImagePaths,
        'status': 'approved', // 审核通过
        'createTime': DateTime.now().toIso8601String(),
      };
      
      // 保存到本地
      bool success;
      if (widget.editMode && widget.editData != null) {
        // 编辑模式：先删除原数据，再保存新数据
        final deleteSuccess = await MomentService.deleteMoment(widget.editData!['id']);
        if (deleteSuccess) {
          success = await MomentService.saveMoment(data);
        } else {
          success = false;
        }
      } else {
        // 新增模式：直接保存
        success = await MomentService.saveMoment(data);
        
        // 发布成功后扣除金币和增加发布次数
        if (success) {
          await _incrementPublishCount();
          if (!_isVipActive() && _todayPublishCount >= 3) {
            await _deductCoins();
          }
        }
      }
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.editMode ? '更新失败，请重试' : '保存失败，请重试')),
          );
        }
        // 如果保存失败，确保键盘不会重新弹出
        _clearFocusAndDismissKeyboard();
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editMode 
                  ? '更新成功！动态将重新进入审核，审核通过后展示在动态广场' 
                  : '发布成功！动态正在审核中，审核通过后将展示在动态广场'
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.of(context).pop(true); // 返回true表示操作成功
      }
      
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
      // 如果发生异常，确保键盘不会重新弹出
      _clearFocusAndDismissKeyboard();
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 收起键盘
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }
  
  // 强制移除焦点并收起键盘
  void _clearFocusAndDismissKeyboard() {
    // 1. 清除输入框的组合状态
    _titleController.clearComposing();
    _contentController.clearComposing();
    
    // 2. 立即移除焦点
    FocusScope.of(context).unfocus();
    
    // 3. 确保当前焦点节点失去焦点
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild!.unfocus();
    }
    
    // 4. 延迟确保彻底清除焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      // 再次确保任何子焦点节点都失去焦点
      final currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        currentFocus.focusedChild!.unfocus();
      }
    });
    
    // 5. 延迟更久一点，确保键盘完全收起
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final currentContext = context;
        if (currentContext.mounted) {
          FocusScope.of(currentContext).unfocus();
        }
      }
    });
  }
  
  // 检查发布限制
  Future<bool> _checkPublishLimit() async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户信息加载失败，请重试')),
      );
      return false;
    }
    
    // 如果是编辑模式，不检查发布限制
    if (widget.editMode) {
      return true;
    }
    
    // 检查是否是VIP
    final isVip = _isVipActive();
    if (isVip) {
      return true; // VIP无限发布
    }
    
    // 检查今日发布次数
    final remainingFreeCount = 3 - _todayPublishCount;
    
    if (remainingFreeCount > 0) {
      // 还有免费机会
      return await _showFreePublishDialog(remainingFreeCount);
    } else {
      // 没有免费机会，检查金币
      if (_userData!.coins >= 10) {
        // 金币充足
        return await _showCoinPublishDialog();
      } else {
        // 金币不足
        return await _showInsufficientCoinDialog();
      }
    }
  }
  
  // 检查VIP状态
  bool _isVipActive() {
    if (_userData?.membershipExpiry == null) return false;
    return DateTime.now().isBefore(_userData!.membershipExpiry);
  }
  
  // 显示免费发布确认弹框
  Future<bool> _showFreePublishDialog(int remainingCount) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '确认发布',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '您今天还有 '),
                    TextSpan(
                      text: '$remainingCount',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' 次免费发布机会\n\n确定要发布这条动态信息吗？'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE44D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '成为VIP会员后可无限制发布',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: const Color(0xFF666666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE44D),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '发布',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 显示金币发布弹框
  Future<bool> _showCoinPublishDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '发布确认',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '您的免费发布次数已用完\n\n发布将消耗 '),
                    TextSpan(
                      text: '10金币',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，当前余额：'),
                    TextSpan(
                      text: '${_userData!.coins}金币',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '选择发布方式：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFE44D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '成为VIP会员后可无限制发布',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '使用金币发布',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          _navigateToVip();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE44D),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '成为VIP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 显示金币不足弹框
  Future<bool> _showInsufficientCoinDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  size: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '金币不足',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '您的免费发布次数已用完\n\n发布需要 '),
                    TextSpan(
                      text: '10金币',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，当前余额：'),
                    TextSpan(
                      text: '${_userData!.coins}金币',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '请选择：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFE44D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '成为VIP会员后可无限制发布',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          _navigateToCoinRecharge();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '去充值',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          _navigateToVip();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE44D),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '成为VIP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 导航到金币充值页面
  void _navigateToCoinRecharge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoinRechargeScreen(
          currentCoins: _userData?.coins ?? 0,
          onRechargeSuccess: () {
            _loadUserData(); // 刷新用户数据
          },
        ),
      ),
    );
  }
  
  // 导航到VIP充值页面
  void _navigateToVip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VipRechargeScreen(
          userData: _userData,
          onRechargeSuccess: () {
            _loadUserData(); // 刷新用户数据
          },
        ),
      ),
    );
  }
  
  // 扣除金币
  Future<void> _deductCoins() async {
    if (_userData == null) return;
    
    try {
      // 扣除10金币
      final newCoins = _userData!.coins - 10;
      final updatedUserData = UserModel(
        name: _userData!.name,
        userId: _userData!.userId,
        coins: newCoins,
        membershipExpiry: _userData!.membershipExpiry,
        personality: _userData!.personality,
        head: _userData!.head,
        originalHead: _userData!.originalHead,
        lovesinger: _userData!.lovesinger,
        lovesong: _userData!.lovesong,
        followCount: _userData!.followCount,
        fansCount: _userData!.fansCount,
      );
      
      // 保存更新后的用户数据
      final success = await KeychainService.saveUserInfo(updatedUserData.toJson());
      if (success) {
        setState(() {
          _userData = updatedUserData;
        });
        debugPrint('扣除金币成功，当前余额：$newCoins');
      } else {
        debugPrint('扣除金币失败');
      }
    } catch (e) {
      debugPrint('扣除金币异常：$e');
    }
  }

  // 增加今日发布次数
  Future<void> _incrementPublishCount() async {
    if (_userData == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'moment_publish_count_${today.year}_${today.month}_${today.day}';

      final count = prefs.getInt(todayKey) ?? 0;
      final newCount = count + 1;

      await prefs.setInt(todayKey, newCount);
      setState(() {
        _todayPublishCount = newCount;
      });
      debugPrint('今日动态发布次数增加成功，当前次数：$newCount');
    } catch (e) {
      debugPrint('增加今日动态发布次数失败: $e');
    }
  }
  
  // 显示收费说明
  void _showPricingInfo() {
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE44D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '发布规则说明',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPricingItem(
                '普通用户',
                '每天3次免费发布机会',
                Icons.person_outline,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildPricingItem(
                '超出免费次数',
                '每发布一次消耗10金币',
                Icons.monetization_on_outlined,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildPricingItem(
                '审核未通过',
                '退回10金币到账户',
                Icons.refresh,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildPricingItem(
                'VIP会员',
                '无限次免费发布',
                Icons.star,
                Colors.purple,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFE44D),
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
  
  // 导航到AI生成器
  Future<void> _navigateToAIGenerator() async {
    // 在导航前先收起键盘
    _clearFocusAndDismissKeyboard();
    
    // 等待键盘完全收起
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const AIContentGeneratorScreen(
          title: '动态内容',
          hintText: '一起来分享令你印象深刻的现场瞬间吧~',
          type: 'moment',
        ),
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _contentController.text = result;
      });
    }
  }

  Widget _buildPricingItem(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _dismissKeyboard,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
        leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
              title: Text(
                widget.editMode ? '编辑动态' : '发动态',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.black),
                  onPressed: _showPricingInfo,
                ),
              ],
      ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // 九宫格图片区域
                        _buildImageGrid(),
                        
                        const SizedBox(height: 20),
                        
                        // 标题输入框
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: '填写标题会有更多赞哦~',
                              hintStyle: TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 内容输入框
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _contentController,
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  hintText: '一起来分享令你印象深刻的现场瞬间吧~',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: _navigateToAIGenerator,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE44D),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'AI生成文案',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_contentController.text.length}/2000',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              
                // 发布按钮
                Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    top: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                                             onPressed: (_isValidating || _isSubmitting) ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFCF15D),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
        child: Text(
                         widget.editMode ? '保存' : '发布',
                         style: const TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
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
        if (_isValidating || _isSubmitting)
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

  // 构建九宫格图片区域
  Widget _buildImageGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 动态计算图片大小：(容器宽度 - 16px间距) / 3
          const double spacing = 8.0;
          final double itemSize = (constraints.maxWidth - spacing * 2) / 3;
          
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              // 显示已选择的图片
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                
                return Stack(
                  children: [
                    Container(
                      width: itemSize,
                      height: itemSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          image,
                          width: itemSize,
                          height: itemSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // 删除按钮
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              
              // 添加图片按钮（当图片数量小于9个时显示）
              if (_selectedImages.length < 9)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                        width: 1,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 30,
                          color: Color(0xFFCCCCCC),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '添加图片',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 