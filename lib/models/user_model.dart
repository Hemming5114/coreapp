class UserModel {
  final String name; // 昵称，对应coredata.json的name
  final int userId;
  final int coins;
  final DateTime membershipExpiry;
  final String personality; // 性格，对应coredata.json的personality
  final String head; // 当前头像，可能是自定义的或原始的
  final String originalHead; // 原始头像，用户注册时生成的默认头像
  final String? lovesinger; // 喜欢的歌手，对应coredata.json的lovesinger
  final String? lovesong; // 喜欢的歌曲，对应coredata.json的lovesong
  final int followCount; // 关注数
  final int fansCount; // 粉丝数

  UserModel({
    required this.name,
    required this.userId,
    required this.coins,
    required this.membershipExpiry,
    required this.personality,
    required this.head,
    required this.originalHead,
    this.lovesinger,
    this.lovesong,
    this.followCount = 0,
    this.fansCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userId': userId,
      'coins': coins,
      'membershipExpiry': membershipExpiry.toIso8601String(),
      'personality': personality,
      'head': head,
      'originalHead': originalHead,
      'lovesinger': lovesinger,
      'lovesong': lovesong,
      'followCount': followCount,
      'fansCount': fansCount,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      userId: json['userId'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      membershipExpiry: json['membershipExpiry'] != null 
          ? DateTime.parse(json['membershipExpiry'] as String)
          : DateTime.now(),
      personality: json['personality'] as String? ?? '',
      head: json['head'] as String? ?? '',
      originalHead: json['originalHead'] as String? ?? (json['head'] as String? ?? ''), // 兼容旧数据，如果没有originalHead则使用head
      lovesinger: json['lovesinger'] as String?,
      lovesong: json['lovesong'] as String?,
      followCount: json['followCount'] as int? ?? 0,
      fansCount: json['fansCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'UserModel(name: $name, userId: $userId, coins: $coins, membershipExpiry: $membershipExpiry, personality: $personality, head: $head, originalHead: $originalHead, lovesinger: $lovesinger, lovesong: $lovesong, followCount: $followCount, fansCount: $fansCount)';
  }
} 