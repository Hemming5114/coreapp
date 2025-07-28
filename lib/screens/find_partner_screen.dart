import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import '../services/partner_service.dart';
import '../services/api_service.dart';
import '../services/image_storage_service.dart';

class FindPartnerScreen extends StatefulWidget {
  final bool editMode;
  final Map<String, dynamic>? editData;
  
  const FindPartnerScreen({
    super.key,
    this.editMode = false,
    this.editData,
  });

  @override
  State<FindPartnerScreen> createState() => _FindPartnerScreenState();
}

class _FindPartnerScreenState extends State<FindPartnerScreen> {
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _expectationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _inviteCountController = TextEditingController();
  
  String _selectedTheme = '现场见';
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isValidating = false;
  
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _themes = [
    '我伙伴', '蹭司机', '拼住宿', '现场见', 
    '自驾拼车', '吃宵夜', '其他主题'
  ];

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑模式，填充现有数据
    if (widget.editMode && widget.editData != null) {
      _fillEditData();
    }
  }
  
  // 填充编辑数据
  Future<void> _fillEditData() async {
    final data = widget.editData!;
    
    _venueController.text = data['venue'] ?? '';
    _expectationController.text = data['expectation'] ?? '';
    _locationController.text = data['location'] ?? '';
    _inviteCountController.text = data['inviteCount']?.toString() ?? '';
    _selectedTheme = data['theme'] ?? '现场见';
    
    if (data['date'] != null) {
      try {
        _selectedDate = DateTime.parse(data['date']);
      } catch (e) {
        debugPrint('解析日期失败: $e');
      }
    }
    
    if (data['coverImage'] != null && data['coverImage'].toString().isNotEmpty) {
      try {
        final fileName = data['coverImage'].toString();
        final fullPath = await ImageStorageService.getImagePath(fileName);
        final imageFile = File(fullPath);
        if (await imageFile.exists()) {
          _selectedImage = imageFile;
        }
      } catch (e) {
        debugPrint('加载封面图片失败: ${data['coverImage']}, $e');
      }
    }
    
    setState(() {});
  }

  @override
  void dispose() {
    _venueController.dispose();
    _expectationController.dispose();
    _locationController.dispose();
    _inviteCountController.dispose();
    super.dispose();
  }

  // 选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
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
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // 选择日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 格式化日期显示
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  // 验证表单数据
  bool _validateForm() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择封面图片')),
      );
      return false;
    }
    
    if (_venueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写演出场次')),
      );
      return false;
    }
    
    if (_expectationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写期望详情')),
      );
      return false;
    }
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择演出时间')),
      );
      return false;
    }
    
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写集结地')),
      );
      return false;
    }
    
    final inviteCount = int.tryParse(_inviteCountController.text);
    if (inviteCount == null || inviteCount < 1 || inviteCount > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邀请人数必须在1-10之间')),
      );
      return false;
    }
    
    return true;
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
    final venue = _venueController.text.trim();
    final expectation = _expectationController.text.trim();
    final location = _locationController.text.trim();
    
    // 1. 先进行本地黑名单检测
    final allText = '$venue $expectation $location';
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
        '请判断这些找搭子信息是否包含明显的不当内容：\n'
        '期望详情："$expectation"\n'
        '检查标准：只需要检查是否包含明显的涉黄、涉黑、政治敏感等严重不当内容。'
        '对于正常的音乐活动邀请、演出搭子寻找等内容应该放行。'
        '如果内容正常，请只回复"通过"。'
        '如果包含明显不当内容，请回复"拒绝：具体原因"。'
      );
      
      debugPrint('找搭子内容验证响应: $response');
      
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
       String? savedImagePath;
       if (_selectedImage != null) {
         savedImagePath = await ImageStorageService.saveImagePermanently(_selectedImage!);
       }
      
       // 构建数据
       final data = {
         'id': DateTime.now().millisecondsSinceEpoch.toString(),
         'coverImage': savedImagePath,
         'venue': _venueController.text.trim(),
         'theme': _selectedTheme,
         'expectation': _expectationController.text.trim(),
         'date': _selectedDate!.toIso8601String(),
         'location': _locationController.text.trim(),
         'inviteCount': int.parse(_inviteCountController.text),
         'status': 'approved', // 审核通过
         'createTime': DateTime.now().toIso8601String(),
       };
       
              // 保存到本地
       bool success;
       if (widget.editMode && widget.editData != null) {
         // 编辑模式：先删除原数据，再保存新数据
         final deleteSuccess = await PartnerService.deletePartnerRequest(widget.editData!['id']);
         if (deleteSuccess) {
           success = await PartnerService.savePartnerRequest(data);
         } else {
           success = false;
         }
       } else {
         // 新增模式：直接保存
         success = await PartnerService.savePartnerRequest(data);
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
                   ? '更新成功！信息将重新进入审核，审核通过后展示在广场' 
                   : '发布成功！信息正在审核中，审核通过后将展示在广场'
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
              widget.editMode ? '编辑找搭子' : '找搭子',
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
                    
                    // 上传封面区域
                    Center(
                      child: GestureDetector(
                        onTap: _selectedImage == null ? _pickImage : null,
                        child: Container(
                          width: 100,
                          height: 133,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: _selectedImage == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 40,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '请上传封面',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImage!,
                                        width: 100,
                                        height: 133,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: _removeImage,
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
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 演出场次
                    const Text(
                      '演出场次',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _venueController,
                            maxLength: 20,
                            decoration: const InputDecoration(
                              hintText: '填写你要去的演出场次哦~',
                              hintStyle: TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              counterText: '',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_venueController.text.length}/20',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 我的主题
                    const Text(
                      '我的主题',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 主题标签
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _themes.map((theme) => _buildThemeTag(theme)).toList(),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expectationController,
                              maxLength: 1000,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                hintText: '写下你对这次找搭子主题的期望详情吧~',
                                hintStyle: TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_expectationController.text.length}/1000',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 演出时间
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildSelectItem(
                        title: '演出时间',
                        value: _selectedDate != null ? _formatDate(_selectedDate!) : '选择演出时间',
                        onTap: _selectDate,
                      ),
                    ),
                    
                                      const SizedBox(height: 12),
                  
                  // 集结地
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '集结地',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: '填写集合的地点',
                              hintStyle: TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    
                    const SizedBox(height: 12),
                    
                                      // 邀请人数
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '邀请人数',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _inviteCountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  if (newValue.text.isEmpty) return newValue;
                                  final int? value = int.tryParse(newValue.text);
                                  if (value == null || value < 1 || value > 10) {
                                    return oldValue;
                                  }
                                  return newValue;
                                }),
                              ],
                              decoration: const InputDecoration(
                                hintText: '请输入邀请人数（1-10人）',
                                hintStyle: TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
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

  Widget _buildThemeTag(String theme) {
    final isSelected = theme == _selectedTheme;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCF15D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.black, width: 1) : Border.all(color: const Color(0xFFE5E5E5), width: 1),
        ),
        child: Text(
          theme,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.black : const Color(0xFF666666),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectItem({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 