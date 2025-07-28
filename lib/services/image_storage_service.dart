import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorageService {
  // 保存图片到应用documents目录
  static Future<String?> saveImagePermanently(File imageFile) async {
    try {
      // 获取应用documents目录
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/saved_images');
      
      // 创建图片目录
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'img_$timestamp$extension';
      final newPath = '${imagesDir.path}/$fileName';
      
      // 复制文件到新位置
      await imageFile.copy(newPath);
      
      return fileName; // 只返回文件名，不返回完整路径
    } catch (e) {
      print('保存图片失败: $e');
      return null;
    }
  }
  
  // 批量保存图片
  static Future<List<String>> saveImagesPermanently(List<File> imageFiles) async {
    List<String> savedPaths = [];
    
    for (File imageFile in imageFiles) {
      final savedPath = await saveImagePermanently(imageFile);
      if (savedPath != null) {
        savedPaths.add(savedPath);
      }
    }
    
    return savedPaths;
  }
  
  // 删除保存的图片
  static Future<bool> deleteImage(String fileName) async {
    try {
      // 如果传入的是完整路径，直接使用；如果是文件名，构建完整路径
      String filePath;
      if (fileName.contains('/')) {
        filePath = fileName; // 完整路径
      } else {
        // 文件名，构建完整路径
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/saved_images/$fileName';
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除图片失败: $e');
      return false;
    }
  }
  
  // 批量删除图片
  static Future<void> deleteImages(List<String> fileNames) async {
    for (String fileName in fileNames) {
      await deleteImage(fileName);
    }
  }
  
  // 获取图片的完整路径
  static Future<String> getImagePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/saved_images/$fileName';
  }
  
  // 检查图片文件是否存在
  static Future<bool> imageExists(String fileName) async {
    try {
      final filePath = await getImagePath(fileName);
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }
  
  // 清理无效的图片文件
  static Future<void> cleanupOrphanedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/saved_images');
      
      if (await imagesDir.exists()) {
        final files = await imagesDir.list().toList();
        for (FileSystemEntity file in files) {
          if (file is File) {
            // 检查文件是否超过30天
            final stat = await file.stat();
            final age = DateTime.now().difference(stat.modified);
            if (age.inDays > 30) {
              await file.delete();
              print('删除过期图片: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      print('清理图片失败: $e');
    }
  }
} 