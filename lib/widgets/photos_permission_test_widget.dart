import 'package:flutter/material.dart';
import '../services/native_photos_permission.dart';

class PhotosPermissionTestWidget extends StatefulWidget {
  const PhotosPermissionTestWidget({super.key});

  @override
  State<PhotosPermissionTestWidget> createState() => _PhotosPermissionTestWidgetState();
}

class _PhotosPermissionTestWidgetState extends State<PhotosPermissionTestWidget> {
  String _permissionStatus = 'unknown';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await NativePhotosPermission.getPhotosPermissionStatus();
      setState(() {
        _permissionStatus = status;
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await NativePhotosPermission.requestPhotosAddPermission(context);
      setState(() {
        _permissionStatus = granted ? 'granted' : 'denied';
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor() {
    switch (_permissionStatus) {
      case 'authorized':
      case 'limited':
      case 'granted':
        return Colors.green;
      case 'denied':
      case 'restricted':
        return Colors.red;
      case 'notDetermined':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_permissionStatus) {
      case 'authorized':
        return '✅ 已授权';
      case 'limited':
        return '⚠️ 有限访问';
      case 'denied':
        return '❌ 已拒绝';
      case 'restricted':
        return '🚫 受限制';
      case 'notDetermined':
        return '❓ 未确定';
      case 'granted':
        return '✅ 已授予';
      default:
        return '❓ $_permissionStatus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'iOS 原生相册权限测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('权限状态: '),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getStatusColor()),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkPermissionStatus,
                  child: const Text('检查权限'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('请求权限'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '说明：此功能仅在iOS设备上有效。Android平台会自动返回已授权状态。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 