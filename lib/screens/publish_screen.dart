import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import '../services/moment_service.dart';
import '../services/api_service.dart';
import '../services/image_storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    
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
        '对于正常的音乐分享、演出体验、生活感悟等内容应该放行。'
        '如果内容正常，请只回复"通过"。'
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
    
    // 收起键盘
    _dismissKeyboard();
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // 内容审核
      final isApproved = await _validateContent();
      
      if (!isApproved) {
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
      }
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.editMode ? '更新失败，请重试' : '保存失败，请重试')),
          );
        }
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
                          child: TextField(
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