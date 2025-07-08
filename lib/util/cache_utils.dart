import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CacheUtils {
  static const String _appName = 'elearn';
  static Directory? _cacheDir;
  
  /// 获取应用缓存目录
  /// 在不同平台上返回合适的用户目录路径
  /// Windows: %APPDATA%\elearn
  /// Android/iOS: 应用缓存目录
  /// macOS/Linux: 应用支持目录
  static Future<Directory> getCacheDirectory() async {
    if (_cacheDir != null) {
      return _cacheDir!;
    }
    
    Directory baseDir;
    
    if (Platform.isWindows) {
      // Windows: 使用 %APPDATA%\elearn，避免com.example前缀
      final appDataPath = Platform.environment['APPDATA'];
      if (appDataPath != null) {
        baseDir = Directory(appDataPath);
      } else {
        baseDir = await getApplicationSupportDirectory();
      }
    } else if (Platform.isAndroid) {
      // Android: 使用应用的缓存目录
      baseDir = await getApplicationCacheDirectory();
    } else if (Platform.isIOS) {
      // iOS: 使用应用的缓存目录
      baseDir = await getApplicationCacheDirectory();
    } else if (Platform.isMacOS) {
      // macOS: 使用应用支持目录
      baseDir = await getApplicationSupportDirectory();
    } else if (Platform.isLinux) {
      // Linux: 使用应用支持目录
      baseDir = await getApplicationSupportDirectory();
    } else {
      // 默认使用临时目录
      baseDir = await getTemporaryDirectory();
    }
    
    _cacheDir = Directory(path.join(baseDir.path, _appName));
    
    // 确保目录存在
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    
    return _cacheDir!;
  }
  
  /// 获取音频缓存目录
  static Future<Directory> getAudioCacheDirectory() async {
    final cacheDir = await getCacheDirectory();
    final audioDir = Directory(path.join(cacheDir.path, 'audio'));
    
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    
    return audioDir;
  }
  
  /// 获取数据库文件路径
  static Future<String> getDatabasePath() async {
    final cacheDir = await getCacheDirectory();
    return path.join(cacheDir.path, 'elearn.db');
  }
  
  /// 清理缓存目录
  static Future<void> clearCache() async {
    final cacheDir = await getCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(recursive: true);
    }
  }
  
  /// 获取缓存目录大小
  static Future<int> getCacheSize() async {
    final cacheDir = await getCacheDirectory();
    if (!await cacheDir.exists()) {
      return 0;
    }
    
    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
  
  /// 格式化缓存大小为可读字符串
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}