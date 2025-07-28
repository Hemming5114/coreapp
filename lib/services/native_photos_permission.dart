import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class NativePhotosPermission {
  static const MethodChannel _channel = MethodChannel('photos_permission');
  
  /// 请求相册写入权限（iOS原生）
  static Future<bool> requestPhotosAddPermission(BuildContext context) async {
    if (!Platform.isIOS) {
      return true; // 非iOS平台默认允许
    }
    
    try {
      final String status = await _channel.invokeMethod('requestPhotosAddPermission');
      
      switch (status) {
        case 'authorized':
        case 'limited':
          return true;
        case 'denied':
          _showPermissionDeniedMessage(context);
          return false;
        case 'restricted':
          _showPermissionRestrictedMessage(context);
          return false;
        case 'notDetermined':
        default:
          return false;
      }
    } catch (e) {
      debugPrint('请求相册权限失败: $e');
      _showPermissionErrorMessage(context);
      return false;
    }
  }
  
  /// 检查相册写入权限状态
  static Future<bool> hasPhotosAddPermission() async {
    if (!Platform.isIOS) {
      return true; // 非iOS平台默认允许
    }
    
    try {
      final String status = await _channel.invokeMethod('checkPhotosAddPermission');
      return status == 'authorized' || status == 'limited';
    } catch (e) {
      debugPrint('检查相册权限失败: $e');
      return false;
    }
  }
  
  /// 获取详细的权限状态
  static Future<String> getPhotosPermissionStatus() async {
    if (!Platform.isIOS) {
      return 'authorized'; // 非iOS平台默认允许
    }
    
    try {
      final String status = await _channel.invokeMethod('checkPhotosAddPermission');
      return status;
    } catch (e) {
      debugPrint('获取相册权限状态失败: $e');
      return 'unknown';
    }
  }
  
  /// 显示权限被拒绝的消息
  static void _showPermissionDeniedMessage(BuildContext context) {
    _showPermissionDialog(
      context,
      '需要相册权限',
      '为了保存图片到相册，需要访问您的照片权限。请在"设置 > 隐私与安全性 > 照片"中允许应用访问您的照片。',
      showGoToSettings: true,
    );
  }
  
  /// 显示权限受限的消息
  static void _showPermissionRestrictedMessage(BuildContext context) {
    _showPermissionDialog(
      context,
      '相册权限受限',
      '由于设备限制，无法访问相册权限。请联系设备管理员或检查家长控制设置。',
      showGoToSettings: false,
    );
  }
  
  /// 显示权限错误的消息
  static void _showPermissionErrorMessage(BuildContext context) {
    _showSnackBar(
      context,
      '获取相册权限失败，请重试',
      Colors.red,
    );
  }
  
  /// 显示权限对话框
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String content, {
    bool showGoToSettings = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('确定'),
            ),
            if (showGoToSettings)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openAppSettings();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                ),
                child: const Text(
                  '去设置',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  /// 显示简单的提示消息
  static void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// 打开应用设置
  static void _openAppSettings() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('openAppSettings');
      } catch (e) {
        debugPrint('打开设置失败: $e');
      }
    }
  }
} 