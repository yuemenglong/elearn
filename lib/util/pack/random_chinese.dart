//import json
// import re
//
// from util.llm import llm_deepseek
//
//
// def normalize_sentence(sentence):
//     """
//     Normalize a sentence by:
//     1. Converting to lowercase
//     2. Removing punctuation
//     """
//     # Convert to lowercase
//     sentence = sentence.lower()
//     # Remove punctuation
//     sentence = re.sub(r'[^\w\s]', '', sentence)
//     # Normalize spaces
//     sentence = re.sub(r'\s+', ' ', sentence).strip()
//     return sentence
//
//
// PromptTpl = """
// 我在进行英文阅读练习，我会给你英文的原文和我阅读后的音频转成的英文文本，你需要判断：
// 1. 两段文本的发音是否一致（或非常相似）
// 2. 两段文本的含义是否一致
//
// 只要满足一个，则返回true,否则返回false
// (因为有可能语音转文字的过程中声音是对的但是字是不对的，这样也算我的阅读正确)
//
// 注意：返回值为一个json对象，前后包在'```'里面
//
// 例如我的输入为：
// a: You're working hard, George.
// b: You are working hard, George.
//
// 你的返回为：
// ```
// {"result": true}
// ```
//
// 下面正式开始：
//
// a: _S1_
// b: _S2_
//
// """
//
//
// def parse_res(res: str):
//     """找到开始和结束的'```',截取里面的部分，转成json格式"""
//     start = res.find('```')
//     end = res.rfind('```')
//     res_obj = json.loads(res[start + 3:end])
//     return res_obj['result']
//
//
// def two_text_diff(original, user):
//     prompt = PromptTpl.replace("_S1_", original).replace("_S2_", user)
//     res = llm_deepseek(prompt)
//     print(res)
//     is_match = parse_res(res)
//     if is_match:
//         return 0
//     else:
//         return 2

import 'dart:convert';
import 'llm.dart';

const String promptTpl = """
我在进行英文学习，具体是我会根据1个英文文本和4个中文文本，选择最正确的中文文本
我会给你一个英文的文本和对应的中文的文本，我需要你参考这两个文本，生成剩下有迷惑性3个答案：

注意：如果给的是一个词，返回的迷惑项目也要是词，如果给的是一个短语/句子，返回的是长度相近的短语/句子
注意：返回的迷惑项目与正确答案不能意思一样，与原来的英文意思也不能一样或相近，要有明显的区别

你的返回格式为：
```
{"result": ["结果1","结果2","结果3"]}
```

下面正式开始：

英文: _EN_
中文: _CN_

""";

Map<String, dynamic> parseRes(String res) {
  try {
    // 查找第一个和最后一个```
    final start = res.indexOf('```');
    final end = res.lastIndexOf('```');
    
    if (start == -1 || end == -1 || start >= end) {
      throw FormatException('未找到有效的JSON代码块');
    }
    
    // 提取```之间的内容
    String jsonStr = res.substring(start + 3, end).trim();
    
    // 移除可能的语言标识符（如json、JSON等）
    if (jsonStr.startsWith('json')) {
      jsonStr = jsonStr.substring(4).trim();
    } else if (jsonStr.startsWith('JSON')) {
      jsonStr = jsonStr.substring(4).trim();
    }
    
    // 查找第一个{和最后一个}，确保提取完整的JSON对象
    final jsonStart = jsonStr.indexOf('{');
    final jsonEnd = jsonStr.lastIndexOf('}');
    
    if (jsonStart == -1 || jsonEnd == -1 || jsonStart >= jsonEnd) {
      throw FormatException('未找到有效的JSON对象');
    }
    
    jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
    
    final resObj = jsonDecode(jsonStr);
    return resObj;
  } catch (e) {
    print('JSON解析错误: $e');
    print('原始响应: $res');
    // 返回默认值，避免应用崩溃
    return {'result': ['选项1', '选项2', '选项3']};
  }
}

Future<List<String>> doRandomChinese(String en, String cn) async {
  final prompt = promptTpl.replaceAll('_CN_', cn).replaceAll('_EN_', en);
  final res = await llmDeepseek(prompt);
  print(res);
  var result = parseRes(res)['result'];
  List<String> ret = [];
  /*将result逐项转为string放入ret*/
  for (var i = 0; i < result.length; i++) {
    ret.add(result[i].toString());
  }
  return ret;
}
