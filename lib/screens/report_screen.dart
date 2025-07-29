import 'package:flutter/material.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String reportType;
  final String title;
  
  const ReportScreen({
    super.key,
    required this.data,
    required this.reportType,
    this.title = '举报',
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
  final List<String> _reportReasons = [
    '垃圾广告',
    '色情低俗',
    '违法违规',
    '不实信息',
    '侮辱谩骂',
    '诈骗信息',
    '版权侵权',
    '恶意刷屏',
    '政治敏感',
    '暴力血腥',
    '其他',
  ];
  
  final Set<String> _selectedReasons = {};
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleReason(String reason) {
    setState(() {
      if (_selectedReasons.contains(reason)) {
        _selectedReasons.remove(reason);
      } else {
        _selectedReasons.add(reason);
      }
    });
    
    // 触发动画
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _submitReport() async {
    if (_selectedReasons.isEmpty && _descriptionController.text.trim().isEmpty) {
      _showMessage('请选择举报理由或填写详细说明', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建举报理由
      final reasonsText = _selectedReasons.join('、');
      final description = _descriptionController.text.trim();
      final reportReason = description.isNotEmpty 
          ? '$reasonsText${reasonsText.isNotEmpty ? ' - ' : ''}$description'
          : reasonsText;

      // 创建举报记录
      String reportedTitle;
      String reportedUser;
      
      if (widget.reportType == 'user') {
        reportedTitle = widget.data['name'] ?? widget.data['userName'] ?? '';
        reportedUser = widget.data['name'] ?? widget.data['userName'] ?? '';
      } else {
        reportedTitle = widget.data['title'] ?? '';
        reportedUser = widget.data['userName'] ?? widget.data['name'] ?? '';
      }
      
      final report = ReportModel(
        id: ReportService.generateReportId(),
        reportedTitle: reportedTitle,
        reportedUser: reportedUser,
        reportTime: DateTime.now(),
        reportReason: reportReason,
        reportType: widget.reportType,
        additionalComment: description.isNotEmpty ? description : null,
      );
      
      // 保存到本地
      await ReportService.saveReport(report);
      
      // 模拟API调用
      await ApiService.testNetworkConnection();
      
      // 延迟一下显示成功效果
      await Future.delayed(const Duration(milliseconds: 800));
      
    } catch (e) {
      debugPrint('举报提交失败: $e');
      _showMessage('提交失败，请重试', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = false;
    });
    
    _showSuccessAndReturn();
  }

  void _showSuccessAndReturn() {
    final tips = [
      '举报成功，我们会尽快处理',
      '感谢举报，维护良好社区环境',
      '举报已提交，客服会及时跟进',
      '举报成功，感谢您的监督',
      '已收到举报，我们会认真核实',
    ];
    final tip = tips[Random().nextInt(tips.length)];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '举报成功',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tip,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE44D),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
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
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白区域收起键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 举报理由标题
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE44D),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '请选择举报理由',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Tag 形式的选项
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _reportReasons.map((reason) {
                                    final isSelected = _selectedReasons.contains(reason);
                                    return GestureDetector(
                                      onTap: () => _toggleReason(reason),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? const Color(0xFFFFE44D)
                                              : const Color(0xFFF0F0F0),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected 
                                                ? const Color(0xFFE6D93B)
                                                : Colors.transparent,
                                            width: 1,
                                          ),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: const Color(0xFFFFE44D).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ] : null,
                                        ),
                                        child: Text(
                                          reason,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected 
                                                ? FontWeight.w500 
                                                : FontWeight.normal,
                                            color: isSelected 
                                                ? Colors.black 
                                                : const Color(0xFF666666),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 详细说明
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE44D),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '详细说明（选填）',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: TextField(
                              controller: _descriptionController,
                              focusNode: _focusNode,
                              maxLines: 4,
                              maxLength: 200,
                              decoration: InputDecoration(
                                hintText: '请详细描述举报内容，有助于我们更好地处理...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F8F8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFE44D),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                                counterStyle: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 温馨提示
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFE44D),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFFF9800),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '我们会认真核实每一份举报，对于恶意举报行为，我们保留追责的权利。感谢您对社区环境的维护！',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.brown[700],
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
            
            // 底部提交按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE44D),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            '提交举报',
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
    );
  }
} 