import 'dart:async';

import '../lesson/lesson.dart';
import '../util/util.dart';
import '../db/quiz_cache.dart';

class QuizStore {
  Lesson lesson;
  bool isCn2En;

  /*这个index包括word和sentence，word走完就继续sentence*/
  int _index = 0;
  Map<int, Completer<List<String>>> options = {};
  Map<int, List<String>> _cachedOptions = {}; // 本地缓存已加载的选项

  QuizStore({
    required this.lesson,
    required this.isCn2En,
  });

  String getEn(int index) {
    if (isFin(index)) {
      return '';
    }
    if (index < lesson.words.length) {
      return lesson.words[index].text;
    } else {
      return lesson.sentences[index - lesson.words.length].text;
    }
  }

  String getCn(int index) {
    if (isFin(index)) {
      return '';
    }
    if (index < lesson.words.length) {
      return lesson.words[index].textCn;
    } else {
      return lesson.sentences[index - lesson.words.length].textCn;
    }
  }

  String getQuestion(int index) {
    if (isFin(index)) {
      return '';
    }
    if (isCn2En) {
      return getCn(index);
    } else {
      return getEn(index);
    }
  }

  String getAnswer(int index) {
    if (isFin(index)) {
      return '';
    }
    if (isCn2En) {
      return getEn(index);
    } else {
      return getCn(index);
    }
  }

  bool isFin(index) {
    return index >= lesson.words.length + lesson.sentences.length;
  }

  String getCurrentQuestion() {
    return getQuestion(_index);
  }

  String getCurrentAnswer() {
    return getAnswer(_index);
  }

  // 批量预加载所有选项
  Future<void> preloadAllOptions() async {
    print("开始预加载所有选项...");
    
    // 首先检查缓存中已有的选项
    List<int> uncachedIndexes = [];
    List<QuizCache> cachedItems = [];
    
    for (var i = 0; i < totalCount(); i++) {
      final question = getQuestion(i);
      final answer = getAnswer(i);
      final type = isCn2En ? 'cn2en' : 'en2cn';
      
      // 检查数据库缓存
      final cached = await QuizCacheMapper.findByKey(question, answer, type);
      if (cached != null) {
        _cachedOptions[i] = cached.getOptionsAsList();
        print("从缓存加载选项 $i: ${cached.getOptionsAsList()}");
      } else {
        uncachedIndexes.add(i);
      }
    }
    
    print("需要请求大模型的题目数量: ${uncachedIndexes.length}");
    
    if (uncachedIndexes.isEmpty) {
      print("所有选项都已缓存，无需请求大模型");
      return;
    }
    
    // 批量请求未缓存的选项
    List<Future<void>> futures = [];
    List<QuizCache> newCaches = [];
    
    for (int i in uncachedIndexes) {
      final future = _generateOptionsForIndex(i).then((options) {
        _cachedOptions[i] = options;
        
        // 创建缓存对象
        final cache = QuizCache(
          question: getQuestion(i),
          answer: getAnswer(i),
          type: isCn2En ? 'cn2en' : 'en2cn',
        );
        cache.setOptionsFromList(options);
        newCaches.add(cache);
        
        print("生成选项 $i: $options");
      });
      
      futures.add(future);
    }
    
    // 等待所有请求完成
    await Future.wait(futures);
    
    // 批量保存到数据库缓存
    if (newCaches.isNotEmpty) {
      await QuizCacheMapper.batchUpsert(newCaches);
      print("批量保存 ${newCaches.length} 个缓存项到数据库");
    }
    
    print("所有选项预加载完成");
  }

  // 为指定索引生成选项（不包含正确答案）
  Future<List<String>> _generateOptionsForIndex(int i) async {
    if (isFin(i)) {
      return [];
    }
    
    var question = getQuestion(i);
    var answer = getAnswer(i);
    
    Future<List<String>>? future;
    if (isCn2En) {
      future = Util.randomEnglish(question, answer);
    } else {
      future = Util.randomChinese(question, answer);
    }
    
    final others = await future;
    var opts = [answer, ...others];
    opts.shuffle();
    return opts;
  }

  void getAllAnswer() {
    // 这个方法保持兼容性，但实际工作由preloadAllOptions完成
    for (var i = 0; i < totalCount(); i++) {
      getOptions(i);
    }
  }

  Future<List<String>> getOptions(int i) async {
    if (isFin(i)) {
      return [];
    }
    
    // 如果已经在本地缓存中，直接返回
    if (_cachedOptions.containsKey(i)) {
      return _cachedOptions[i]!;
    }
    
    // 如果已经有正在进行的请求，返回该请求的Future
    if (options.containsKey(i)) {
      return options[i]!.future;
    }
    
    // 检查数据库缓存
    final question = getQuestion(i);
    final answer = getAnswer(i);
    final type = isCn2En ? 'cn2en' : 'en2cn';
    
    final cached = await QuizCacheMapper.findByKey(question, answer, type);
    if (cached != null) {
      final cachedOptions = cached.getOptionsAsList();
      _cachedOptions[i] = cachedOptions;
      return cachedOptions;
    }
    
    // 创建新的请求
    var completer = Completer<List<String>>();
    options[i] = completer;
    
    try {
      final generatedOptions = await _generateOptionsForIndex(i);
      _cachedOptions[i] = generatedOptions;
      
      // 保存到数据库缓存
      final cache = QuizCache(
        question: question,
        answer: answer,
        type: type,
      );
      cache.setOptionsFromList(generatedOptions);
      await QuizCacheMapper.upsert(cache);
      
      completer.complete(generatedOptions);
      return generatedOptions;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    }
  }

  Future<List<String>> getCurrentOptions() async {
    // 预加载下一题的选项（如果还没有加载的话）
    if (_index + 1 < totalCount()) {
      getOptions(_index + 1);
    }
    return getOptions(_index);
  }

  void moveNext() {
    _index++;
  }

  bool isFinish() {
    return isFin(_index);
  }

  int totalCount() {
    return lesson.words.length + lesson.sentences.length;
  }
}
