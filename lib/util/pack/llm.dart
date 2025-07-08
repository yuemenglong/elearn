import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../const/key.dart';

class OpenAI {
  final String apiKey;
  final String baseUrl;

  OpenAI({required this.apiKey, required this.baseUrl});

  Future<String> chatCompletions({
    required String model,
    required List<Map<String, String>> messages,
    int maxTokens = 8192,
    double temperature = 0.3,
    bool stream = false,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': stream,
    });

    while (true) {
      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          final result = utf8.decode(response.bodyBytes);
          final responseData = jsonDecode(result);
          return responseData['choices'][0]['message']['content'];
        } else {
          print('Request failed with status: ${response.statusCode}. Retrying...');
          await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
        }
      } catch (e) {
        print('Error occurred: $e. Retrying...');
        await Future.delayed(const Duration(seconds: 2)); // 等待 2 秒后重试
      }
    }
  }
}

Future<String> llmDeepseek(String prompt) async {
  final client = OpenAI(apiKey: Key.config_api_key_deepseek, baseUrl: Key.config_base_url_deepseek);
  print("请求deepseek");
  final response = await client.chatCompletions(
    model: Key.config_model_deepseek,
    messages: [
      {'role': 'system', 'content': '你是一个英语老师，帮我解答我的英语问题'},
      {'role': 'user', 'content': prompt},
    ],
    maxTokens: 8192,
    temperature: 0.3,
    stream: false,
  );
  return response;
}

Future<String> llmCompletion(String prompt) async {
  return await llmDeepseek(prompt);
}

void main() async {
  try {
    final prompt = 'What is the past tense of "go"?';
    final response = await llmCompletion(prompt);
    print('Response: $response');
  } catch (e) {
    print('Error: $e');
  }
}
