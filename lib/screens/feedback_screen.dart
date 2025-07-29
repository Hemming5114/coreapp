import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _feedbackTypes = [
    '功能建议',
    '界面优化',
    'Bug反馈',
    '内容举报',
    '其他问题',
  ];
  String _selectedType = '功能建议';
  bool _includeContact = false;
  final TextEditingController _contactController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '意见反馈',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submitFeedback,
            child: const Text(
              '提交',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFE44D),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白收起键盘
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 反馈类型选择
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '反馈类型',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    ..._feedbackTypes.map((type) => _buildTypeItem(type)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 反馈内容
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '反馈内容',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: 8,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: '请详细描述您的问题或建议...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFE44D),
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 联系方式
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        '留下联系方式',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: const Text(
                        '方便我们回复您的问题',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      value: _includeContact,
                      onChanged: (value) {
                        setState(() {
                          _includeContact = value;
                        });
                      },
                      activeColor: const Color(0xFFFFE44D),
                    ),
                    if (_includeContact)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: TextField(
                          controller: _contactController,
                          decoration: InputDecoration(
                            hintText: '请输入您的邮箱或手机号',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFE44D),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 提示信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE44D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFE44D).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFE44D),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '感谢您的反馈！我们会认真处理您的建议，努力改进产品体验。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeItem(String type) {
    final isSelected = _selectedType == type;
    return RadioListTile<String>(
      title: Text(
        type,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? const Color(0xFFFFE44D) : Colors.black,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      value: type,
      groupValue: _selectedType,
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
        });
      },
      activeColor: const Color(0xFFFFE44D),
    );
  }

  void _submitFeedback() {
    final content = _feedbackController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入反馈内容'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: 提交反馈到服务器
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('反馈提交成功！感谢您的建议'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
    
    // 清空输入
    _feedbackController.clear();
    _contactController.clear();
    setState(() {
      _selectedType = '功能建议';
      _includeContact = false;
    });
    
    // 返回上一页
    Navigator.pop(context);
  }
} 