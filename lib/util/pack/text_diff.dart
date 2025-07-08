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
import 'package:flutter/services.dart';

import 'llm.dart';

String normalizeSentence(String sentence) {
  // Convert to lowercase
  sentence = sentence.toLowerCase();
  // Remove punctuation
  sentence = sentence.replaceAll(RegExp(r'[^\w\s]'), '');
  // Normalize spaces
  sentence = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
  return sentence;
}

const String promptTpl = """
我在进行英文阅读练习，我会给你英文的原文和我阅读后的音频转成的英文文本，你需要判断：
1. 两段文本的发音是否一致（或非常相似）
2. 两段文本的含义是否一致

只要满足一个，则返回true,否则返回false
(因为有可能语音转文字的过程中声音是对的但是字是不对的，这样也算我的阅读正确)
注意，如果一个是陈述句例如this is,而另一个是疑问句例如is this，则这两个是不一样的

以下都是发音类似的词或短句，如果出现则认为是阅读正确
_SIM_


注意：返回值为一个json对象，前后包在'```'里面

例如我的输入为：
a: You're working hard, George.
b: You are working hard, George.

你的返回为：
```
{"result": true}
```

下面正式开始：

a: _S1_
b: _S2_

""";

Map<String, dynamic> parseRes(String res) {
  final start = res.indexOf('```');
  final end = res.lastIndexOf('```');
  final resObj = jsonDecode(res.substring(start + 3, end));
  return resObj;
}

Future<bool> doTextIsSame(String original, String user) async {
  var sim = await rootBundle.loadString("assets/sim.txt");
  final prompt = promptTpl.replaceAll('_S1_', original).replaceAll('_S2_', user).replaceAll('_SIM_', sim);
  final res = await llmDeepseek(prompt);
  print(res);
  final isMatch = parseRes(res)['result'];
  return isMatch;
}
