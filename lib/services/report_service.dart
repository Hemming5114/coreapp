import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';

class ReportService {
  static const String _reportHistoryKey = 'report_history';

  // 保存举报记录到本地
  static Future<void> saveReport(ReportModel report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReportHistory();
    reports.add(report);
    
    final reportsJson = reports.map((r) => r.toJson()).toList();
    await prefs.setString(_reportHistoryKey, jsonEncode(reportsJson));
  }

  // 获取举报历史
  static Future<List<ReportModel>> getReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportHistoryKey);
    
    if (reportsJson == null) {
      return [];
    }

    try {
      final List<dynamic> reportsList = jsonDecode(reportsJson);
      return reportsList.map((json) => ReportModel.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing report history: $e');
      return [];
    }
  }

  // 清除举报历史
  static Future<void> clearReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportHistoryKey);
  }

  // 生成唯一ID
  static String generateReportId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
} 