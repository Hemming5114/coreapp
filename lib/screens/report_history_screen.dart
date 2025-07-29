import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await ReportService.getReportHistory();
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载举报历史失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '举报历史',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_reports.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('清空举报历史'),
                    content: const Text('确定要清空所有举报记录吗？此操作无法撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ReportService.clearReportHistory();
                          Navigator.pop(context);
                          _loadReports();
                        },
                        child: const Text('确定', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                '清空',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFE44D),
              ),
            )
          : _reports.isEmpty
              ? _buildEmptyState()
              : _buildReportList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE44D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              size: 50,
              color: Color(0xFFFFE44D),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无举报记录',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您还没有举报过任何内容',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9598AC),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE44D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '💡 遇到不当内容可以进行举报',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9598AC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFFFE44D),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report, index);
        },
      ),
    );
  }

  Widget _buildReportCard(ReportModel report, int index) {
    final statusInfo = ReportService.getReportStatusInfo(report);
    final statusText = statusInfo['text'] as String;
    final statusColor = statusInfo['color'] as Color;

    IconData typeIcon;
    Color typeColor;
    String typeText;

    switch (report.reportType) {
      case 'user':
        typeIcon = Icons.person_outline;
        typeColor = const Color(0xFF007AFF);
        typeText = '用户';
        break;
      case 'plaza':
        typeIcon = Icons.place_outlined;
        typeColor = const Color(0xFF34C759);
        typeText = '广场';
        break;
      case 'feed':
        typeIcon = Icons.dynamic_feed_outlined;
        typeColor = const Color(0xFFFF9500);
        typeText = '动态';
        break;
      default:
        typeIcon = Icons.report_outlined;
        typeColor = const Color(0xFF8E8E93);
        typeText = '未知';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部状态条
            Container(
              width: double.infinity,
              height: 4,
              color: statusColor,
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部信息行
                  Row(
                    children: [
                      // 类型标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 16, color: typeColor),
                            const SizedBox(width: 6),
                            Text(
                              typeText,
                              style: TextStyle(
                                fontSize: 14,
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      
                      // 状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 14,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 被举报内容标题
                  Text(
                    report.reportedTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // 被举报用户
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Color(0xFF9598AC),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.reportedUser,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9598AC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 举报理由
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        size: 18,
                        color: Color(0xFF9598AC),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.reportReason,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF171717),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // 附加说明（如果有）
                  if (report.additionalComment != null && report.additionalComment!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Color(0xFF9598AC),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.additionalComment!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF171717),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // 底部时间
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF9598AC),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(report.reportTime),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9598AC),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '举报 #${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9598AC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1天前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}天前';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months}个月前';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years}年前';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 