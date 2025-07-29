import 'package:flutter/services.dart';

class IDFAService {
  static const MethodChannel _channel = MethodChannel('idfa_service');

  /// 获取设备标识符（IDFA）
  static Future<String> getDeviceIdentifier() async {
    try {
      final String idfa = await _channel.invokeMethod('getDeviceIdentifier');
      return idfa;
    } on PlatformException catch (e) {
      print('获取设备标识符失败: ${e.message}');
      return "";
    }
  }

  /// 获取广告标识符
  static Future<String> getAdvertisingId() async {
    try {
      final String idfa = await _channel.invokeMethod('getAdvertisingId');
      return idfa;
    } on PlatformException catch (e) {
      print('获取广告标识符失败: ${e.message}');
      return "";
    }
  }

  /// 获取设备类型
  static Future<String> getDeviceType() async {
    try {
      final String deviceType = await _channel.invokeMethod('getDeviceType');
      return deviceType;
    } on PlatformException catch (e) {
      print('获取设备类型失败: ${e.message}');
      return "unknown";
    }
  }
} 