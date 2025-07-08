import 'dart:convert'; // 引入 dart:convert
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:record_example/util/pack/refresh_token.dart';

import '../../const/key.dart';

Future<Map<String, dynamic>?> recognizeSpeech(String appKey, String token, String audioFile,
    {String format = "pcm",
    int sampleRate = 16000,
    bool enablePunctuationPrediction = true,
    bool enableInverseTextNormalization = true}) async {
  // Service URL
  const url = "https://nls-gateway-cn-shanghai.aliyuncs.com/stream/v1/asr";

  // Request parameters
  final params = {
    "appkey": appKey,
    "format": format,
    "sample_rate": sampleRate.toString(),
    "enable_punctuation_prediction": enablePunctuationPrediction.toString().toLowerCase(),
    "enable_inverse_text_normalization": enableInverseTextNormalization.toString().toLowerCase(),
  };

  // Request headers
  final headers = {
    "X-NLS-Token": token,
    "Content-Type": "application/octet-stream",
  };

  // Read audio file
  final audioData = await File(audioFile).readAsBytes();

  // Send POST request
  final uri = Uri.parse(url).replace(queryParameters: params);
  print("Sending POST request to $uri with headers $headers");

  while (true) {
    try {
      final response = await http.post(uri, headers: headers, body: audioData);

      // Parse response
      if (response.statusCode == 200) {
        // 显式使用 UTF-8 解码
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        print("Response body: $result");
        return result;
      } else {
        print("Request failed, status code: ${response.statusCode}");
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        print("Response body: $result");
        await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
      }
    } catch (e) {
      print("Error occurred: $e. Retrying...");
      await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
    }
  }
}

Future<String> doGetTextFromAudio(String path) async {
  const appKey = Key.AppKey;
  final token = doGetToken();
  final result = await recognizeSpeech(appKey, token, path);

  // Output recognition result
  if (result != null && result["status"] == 20000000) {
    print("Recognition succeeded!");
    print("Recognition result: ${result["result"]}");
    return result["result"];
  } else {
    print("Recognition failed!");
    print("Error message: $result");
    return "";
  }
}
