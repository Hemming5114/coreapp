import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/native_photos_permission.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String imageBasePath; // 'assets/images/iconImg/' 或其他路径前缀

  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.imageBasePath = 'assets/images/iconImg/',
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  Future<void> _saveImage() async {
    try {
      // 使用iOS原生Photos权限检查
      final hasPermission = await NativePhotosPermission.requestPhotosAddPermission(context);
      if (!hasPermission) {
        return; // 权限服务已经处理了用户提示
      }

      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('正在保存图片...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 获取当前图片路径
      final currentImage = widget.images[_currentIndex];
      final imagePath = '${widget.imageBasePath}$currentImage';

      // 加载assets图片并保存
      final ByteData data = await rootBundle.load(imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // 创建临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      // 保存到相册
      await Gal.putImage(tempFile.path);

      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片已保存到相册'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('保存图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存图片失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    // 添加空列表检查
    if (widget.images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // 顶部返回按钮
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // 错误提示
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '没有可显示的图片',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片查看器
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final imagePath = '${widget.imageBasePath}${widget.images[index]}';
              debugPrint('Loading image: $imagePath');
              
              return PhotoViewGalleryPageOptions(
                imageProvider: AssetImage(imagePath),
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: "image_$index"),
                onTapUp: (context, details, controllerValue) {
                  if (mounted) {
                    _toggleUI();
                  }
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Image load error: $error');
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '图片加载失败',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
          ),
          
          // 顶部UI层
          AnimatedOpacity(
            opacity: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 返回按钮
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      
                      // 图片计数
                      if (widget.images.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      
                      // 保存按钮
                      IconButton(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _saveImage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 底部指示器（仅在多张图片时显示）
          if (widget.images.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 