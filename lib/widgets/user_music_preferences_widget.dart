import 'package:flutter/material.dart';

class UserMusicPreferencesWidget extends StatelessWidget {
  final String? loveSinger;
  final String? loveSong;
  final bool isOwn; // 是否是自己的信息
  final VoidCallback? onTap; // 点击回调，用于编辑功能
  
  const UserMusicPreferencesWidget({
    super.key,
    this.loveSinger,
    this.loveSong,
    this.isOwn = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 最喜欢的歌手
        Expanded(
          child: GestureDetector(
            onTap: (isOwn && (loveSinger?.isEmpty ?? true)) ? onTap : null,
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // 背景图片层（放在底层）
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Image.asset(
                        'assets/images/appicon/btn_home_singer.webp',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.red, // 改为红色以便调试
                            child: const Icon(
                              Icons.error,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    // 文案内容层（放在上层，透明背景）
                    Positioned.fill(
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isOwn ? '我最喜欢的歌手' : 'Ta最喜欢的歌手',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF824CEF).withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (isOwn && (loveSinger?.isEmpty ?? true)) 
                                  ? '去编辑 >' 
                                  : (loveSinger ?? '未设置'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF824CEF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 最喜欢的歌曲
        Expanded(
          child: GestureDetector(
            onTap: (isOwn && (loveSong?.isEmpty ?? true)) ? onTap : null,
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDEA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // 背景图片层（放在底层）
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Image.asset(
                        'assets/images/appicon/btn_home_song.webp',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.red, // 改为红色以便调试
                            child: const Icon(
                              Icons.error,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    // 文案内容层（放在上层，透明背景）
                    Positioned.fill(
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isOwn ? '我最喜欢的歌曲' : 'Ta最喜欢的歌曲',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFFEB5F47).withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (isOwn && (loveSong?.isEmpty ?? true)) 
                                  ? '去编辑 >' 
                                  : (loveSong ?? '未设置'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFEB5F47),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 