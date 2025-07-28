import 'package:flutter/material.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';

class FeedReportScreen extends StatefulWidget {
  final Map<String, dynamic> feed;
  final String reportType;
  const FeedReportScreen({Key? key, required this.feed, required this.reportType}) : super(key: key);

  @override
  State<FeedReportScreen> createState() => _FeedReportScreenState();
}

class _FeedReportScreenState extends State<FeedReportScreen> {
  final List<String> reasons = [
    '不实信息',
    '广告骚扰',
    '涉及违法',
    '色情低俗',
    '侮辱谩骂',
    '其它',
  ];
  final Set<int> selected = {};
  final TextEditingController controller = TextEditingController();
  bool loading = false;

  Future<void> _submitReport() async {
    if (selected.isEmpty && controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择举报理由或填写说明')));
      return;
    }
    setState(() { loading = true; });
    
    try {
      // 构建举报理由
      final selectedReasons = selected.map((i) => reasons[i]).join('、');
      final reportReason = controller.text.trim().isNotEmpty 
          ? '$selectedReasons - ${controller.text.trim()}'
          : selectedReasons;
      
      // 创建举报记录
      final report = ReportModel(
        id: ReportService.generateReportId(),
        reportedTitle: widget.feed['title'] ?? '',
        reportedUser: widget.feed['userName'] ?? '',
        reportTime: DateTime.now(),
        reportReason: reportReason,
        reportType: widget.reportType,
        additionalComment: controller.text.trim().isNotEmpty ? controller.text.trim() : null,
      );
      
      // 保存到本地
      await ReportService.saveReport(report);
      
      // 模拟API调用
      await ApiService.testNetworkConnection();
      
    } catch (e) {
      debugPrint('举报请求失败: $e');
    }
    
    setState(() { loading = false; });
    
    final tips = [
      '举报成功，客服会尽快核实处理。',
      '举报已提交，感谢您的反馈！',
      '举报成功，平台将尽快核查。',
      '举报已收到，工作人员会及时跟进。',
      '举报成功，感谢您的监督与支持！',
    ];
    final tip = tips[Random().nextInt(tips.length)];
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(tip),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('举报'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择举报理由', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(reasons.length, (i) => CheckboxListTile(
              value: selected.contains(i),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selected.add(i);
                  } else {
                    selected.remove(i);
                  }
                });
              },
              title: Text(reasons[i]),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 20),
            const Text('补充说明（选填）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '请补充举报说明（选填）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE44D),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('提交举报', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 