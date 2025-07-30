import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import 'package:flutter/material.dart'; // Added for Color

// 举报状态枚举
enum ReportStatus {
  pending,    // 客服核实中
  processing, // 处理中
  resolved,   // 已处理
  rejected,   // 已驳回
}

class ReportService {
  static const String _reportHistoryKey = 'report_history';

  // 保存举报记录到本地
  static Future<void> saveReport(ReportModel report) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReportHistory();
    reports.add(report);
    
    final reportsJson = reports.map((r) => r.toJson()).toList();
    await prefs.setString(_reportHistoryKey, jsonEncode(reportsJson));
      
      debugPrint('举报记录保存成功: ${report.reportType} - ${report.reportedTitle}');
    } catch (e) {
      debugPrint('保存举报记录失败: $e');
      rethrow;
    }
  }

  // 获取举报历史
  static Future<List<ReportModel>> getReportHistory() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportHistoryKey);
    
      if (reportsJson == null || reportsJson.isEmpty) {
      return [];
    }

      final List<dynamic> reportsList = jsonDecode(reportsJson);
      final reports = reportsList.map((json) => ReportModel.fromJson(json)).toList();
      
      // 按时间倒序排列（最新的在前面）
      reports.sort((a, b) => b.reportTime.compareTo(a.reportTime));
      
      debugPrint('获取到举报记录数量: ${reports.length}');
      return reports;
    } catch (e) {
      debugPrint('获取举报历史失败: $e');
      return [];
    }
  }

  // 清除举报历史
  static Future<void> clearReportHistory() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportHistoryKey);
      debugPrint('举报历史已清除');
    } catch (e) {
      debugPrint('清除举报历史失败: $e');
    }
  }

  // 生成唯一ID
  static String generateReportId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // 根据类型获取举报历史
  static Future<List<ReportModel>> getReportsByType(String type) async {
    final allReports = await getReportHistory();
    return allReports.where((report) => report.reportType == type).toList();
  }

  // 获取举报状态显示文本和颜色
  static Map<String, dynamic> getReportStatusInfo(ReportModel report) {
    // 模拟状态逻辑：
    // - 3天内的举报为"客服核实中"
    // - 3-7天的为"处理中" 
    // - 7天以上的为"已处理"
    final daysSinceReport = DateTime.now().difference(report.reportTime).inDays;
    
    String statusText;
    Color statusColor;
    
    if (daysSinceReport <= 3) {
      statusText = '客服核实中';
      statusColor = const Color(0xFFFF9500); // 橙色
    } else if (daysSinceReport <= 7) {
      statusText = '处理中';
      statusColor = const Color(0xFF007AFF); // 蓝色
    } else {
      statusText = '已处理';
      statusColor = const Color(0xFF34C759); // 绿色
    }
    
    return {
      'text': statusText,
      'color': statusColor,
    };
  }
} 