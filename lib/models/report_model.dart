class ReportModel {
  final String id;
  final String reportedTitle; // 被举报的标题
  final String reportedUser; // 被举报的用户
  final DateTime reportTime; // 举报时间
  final String reportReason; // 举报理由
  final String reportType; // 被举报的类型 (plaza/feed)
  final String? additionalComment; // 附加评论

  ReportModel({
    required this.id,
    required this.reportedTitle,
    required this.reportedUser,
    required this.reportTime,
    required this.reportReason,
    required this.reportType,
    this.additionalComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportedTitle': reportedTitle,
      'reportedUser': reportedUser,
      'reportTime': reportTime.toIso8601String(),
      'reportReason': reportReason,
      'reportType': reportType,
      'additionalComment': additionalComment,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      reportedTitle: json['reportedTitle'],
      reportedUser: json['reportedUser'],
      reportTime: DateTime.parse(json['reportTime']),
      reportReason: json['reportReason'],
      reportType: json['reportType'],
      additionalComment: json['additionalComment'],
    );
  }
} 