import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../../const/key.dart';
import '../cache_utils.dart';
import 'refresh_token.dart';

enum TtsProvider {
  aliyun,
  doubao,
}

Future<String> _getAudioCachePath(String text) async {
  final bytes = utf8.encode(text);
  final hash = md5.convert(bytes).toString();
  final audioDir = await CacheUtils.getAudioCacheDirectory();
  return path.join(audioDir.path, '$hash.wav');
}

Future<void> _ensureCacheDirectoryExists() async {
  // 使用新的缓存工具类确保目录存在
  await CacheUtils.getAudioCacheDirectory();
}

Future<bool> _copyFile(String source, String destination) async {
  try {
    await File(source).copy(destination);
    return true;
  } catch (e) {
    print("Error copying file: $e");
    return false;
  }
}

Future<void> _textToSpeechPost(String appKey, String token, String text, String audioSaveFile,
    {String format = "wav", int sampleRate = 16000}) async {
  // Set service URL
  const url = "https://nls-gateway-cn-shanghai.aliyuncs.com/stream/v1/tts";

  // Construct request body
  final requestBody = jsonEncode({
    "appkey": appKey,
    "token": token,
    "text": text,
    "format": format,
    "sample_rate": sampleRate,
  });

  final headers = {"Content-Type": "application/json"};

  while (true) {
    try {
      // Send POST request
      final response = await http.post(Uri.parse(url), headers: headers, body: requestBody);

      // Handle response
      final contentType = response.headers["content-type"];
      if (contentType == "audio/mpeg") {
        final audioFile = File(audioSaveFile);
        await audioFile.writeAsBytes(response.bodyBytes);
        print("Aliyun TTS succeeded, audio saved to: $audioSaveFile");
        return; // 成功时退出循环
      } else {
        final errorMessage = response.body;
        print("Aliyun TTS failed: $errorMessage. Retrying...");
        await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
      }
    } catch (e) {
      print("Error occurred: $e. Retrying...");
      await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
    }
  }
}

Future<void> _doubaoTtsPost(String appId, String accessToken, String text, String audioSaveFile,
    {String encoding = "mp3", String voiceType = "zh_female_yingyujiaoyu_mars_bigtts"}) async {
  // Set service URL
  const url = "https://openspeech.bytedance.com/api/v1/tts";

  // Generate request ID
  final reqId = DateTime.now().millisecondsSinceEpoch.toString();

  // Construct request body
  final requestBody = jsonEncode({
    "app": {
      "appid": appId,
      "cluster": "volcano_tts",
    },
    "user": {
      "uid": "uid"
    },
    "audio": {
      "voice_type": voiceType,
      "encoding": encoding,
    },
    "request": {
      "reqid": reqId,
      "text": text,
      "operation": "query",
    }
  });

  final headers = {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": "Bearer;$accessToken"
  };

  while (true) {
    try {
      // Send POST request
      final response = await http.post(Uri.parse(url), headers: headers, body: requestBody);

      // Handle response
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final code = responseData['code'];
          
          if (code == 3000) { // 成功状态码
            final data = responseData['data'];
            if (data != null && data.isNotEmpty) {
              // 解码base64数据
              final audioBytes = base64Decode(data);
              final audioFile = File(audioSaveFile);
              await audioFile.writeAsBytes(audioBytes);
              print("Doubao TTS succeeded, audio saved to: $audioSaveFile (${audioBytes.length} bytes)");
              return; // 成功时退出循环
            } else {
              print("Doubao TTS failed: No audio data in response. Retrying...");
            }
          } else {
            final message = responseData['message'] ?? 'Unknown error';
            print("Doubao TTS failed with code $code: $message. Retrying...");
          }
        } catch (e) {
          print("Doubao TTS failed to parse response: $e. Retrying...");
        }
        
        await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
      } else {
        final errorMessage = response.body;
        print("Doubao TTS failed with status ${response.statusCode}: $errorMessage. Retrying...");
        await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
      }
    } catch (e) {
      print("Error occurred: $e. Retrying...");
      await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
    }
  }
}

Future<void> doGetAudioFromText(String text, String saveFile, {TtsProvider provider = TtsProvider.aliyun}) async {
  await _ensureCacheDirectoryExists();
  final cachePath = await _getAudioCachePath(text);
  
  // Check if cached version exists
  if (await File(cachePath).exists()) {
    final success = await _copyFile(cachePath, saveFile);
    if (success) {
      print("Audio retrieved from cache: $saveFile");
      return;
    }
  }

  // If not in cache or copy failed, generate new audio
  switch (provider) {
    case TtsProvider.aliyun:
      final token = doGetToken();
      await _textToSpeechPost(Key.AppKey, token, text, saveFile);
      break;
    case TtsProvider.doubao:
      await _doubaoTtsPost(Key.doubao_app_id, Key.doubao_access_token, text, saveFile);
      break;
  }
  
  // Cache the newly generated audio
  await _copyFile(saveFile, cachePath);
}

// 为了向后兼容，保留原有的函数，默认使用阿里云
Future<void> doGetAudioFromTextAliyun(String text, String saveFile) async {
  await doGetAudioFromText(text, saveFile, provider: TtsProvider.aliyun);
}

// 新增：使用doubao接口的函数
Future<void> doGetAudioFromTextDoubao(String text, String saveFile) async {
  await doGetAudioFromText(text, saveFile, provider: TtsProvider.doubao);
}
