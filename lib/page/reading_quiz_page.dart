import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record_example/lesson/lesson.dart';
import 'package:record_example/const/const.dart';
import 'package:record_example/page/reading_quiz_hist.dart';
import 'package:record_example/util/pack/get_text_from_audio.dart';
import 'package:record_example/util/pack/play_audio.dart';
import 'package:record_example/widget/choose_lesson.dart';
import 'package:record_example/widget/edit_favour_sentence.dart';

import '../context/context.dart';
import '../db/user_settings.dart';
import '../util/util.dart';
import '../db/star.dart';

class ReadingQuizPage extends StatefulWidget {
  const ReadingQuizPage({super.key});

  @override
  State<ReadingQuizPage> createState() => _ReadingQuizPageState();
}

class _ReadingQuizPageState extends State<ReadingQuizPage> {
  bool showAnswer = false;
  bool isPlaying = false;  // 添加播放状态
  bool showButtons = false;  // 添加按钮显示状态
  int currentIndex = 0;
  late List<Lesson> lessons;
  Lesson? lesson;  // 改为可空，表示未选择课程
  int correctCount = 0;
  int wrongCount = 0;
  bool isStarted = false;  // 新增：是否已开始测试
  bool hasLastProgress = false; // 是否有上次的进度

  @override
  void initState() {
    super.initState();
    _loadLessonsAndProgress();
  }

  // 加载课程和上次的进度
  void _loadLessonsAndProgress() async {
    final allLessons = await LessonStore.getLessons();
    final currentAccount = AppContext.getCurrentAccount();
    
    // 获取上次选择的课程
    final lastSelectedLessonNo = await UserSettingsMapper.getSetting(
      currentAccount, 
      'reading_quiz_last_lesson'
    );
    
    // 获取上次的进度
    final lastProgress = await UserSettingsMapper.getSetting(
      currentAccount,
      'reading_quiz_last_progress'
    );
    
    Lesson? selectedLesson;
    int lastIndex = 0;
    bool hasProgress = false;
    
    if (lastSelectedLessonNo != null) {
      try {
        final lessonNo = int.parse(lastSelectedLessonNo);
        selectedLesson = allLessons.where((lesson) => lesson.number == lessonNo).firstOrNull;
        
        if (selectedLesson != null && lastProgress != null) {
          lastIndex = int.parse(lastProgress);
          hasProgress = lastIndex > 0;
          print("恢复上次测试: ${selectedLesson.title}, 进度: $lastIndex");
        }
      } catch (e) {
        print("恢复上次测试失败: $e");
      }
    }
    
    setState(() {
      lessons = allLessons;
      lesson = selectedLesson;
      currentIndex = lastIndex;
      hasLastProgress = hasProgress;
    });
  }

  // 保存当前进度
  Future<void> _saveProgress() async {
    if (lesson != null) {
      final currentAccount = AppContext.getCurrentAccount();
      await UserSettingsMapper.saveSetting(
        currentAccount,
        'reading_quiz_last_lesson',
        lesson!.number.toString(),
      );
      await UserSettingsMapper.saveSetting(
        currentAccount,
        'reading_quiz_last_progress',
        currentIndex.toString(),
      );
    }
  }

  Future<void> _selectLesson(Lesson selectedLesson) async {
    final currentAccount = AppContext.getCurrentAccount();
    await UserSettingsMapper.saveSetting(
      currentAccount,
      'reading_quiz_last_lesson',
      selectedLesson.number.toString(),
    );
    await UserSettingsMapper.saveSetting(
      currentAccount,
      'reading_quiz_last_progress',
      '0',
    );
    
    setState(() {
      lesson = selectedLesson;
      currentIndex = 0;
      showAnswer = false;
      isStarted = false;  // 选择新课程后重置状态
      correctCount = 0;   // 重置计数
      wrongCount = 0;
      hasLastProgress = false;
    });
  }

  void _startLesson() {
    setState(() {
      isStarted = true;
      currentIndex = 0;
      showAnswer = false;
      correctCount = 0;
      wrongCount = 0;
      hasLastProgress = false;
    });
    _saveProgress();
  }

  // 继续上次的测试
  void _continueLastTest() {
    setState(() {
      isStarted = true;
      showAnswer = false;
      // 保持当前的currentIndex不变
      hasLastProgress = false;
    });
  }

  void _restartLesson() {
    setState(() {
      isStarted = true;
      currentIndex = 0;
      showAnswer = false;
      correctCount = 0;
      wrongCount = 0;
      hasLastProgress = false;
    });
    _saveProgress();
  }

  void _nextSentence() async {
    if (!showAnswer) {
      // 获取音频文件并播放
      setState(() {
        showAnswer = true;
        showButtons = false;  // 隐藏按钮
        isPlaying = true;
      });

      // 播放当前句子的英文
      await Util.getAudioFromText(lesson!.sentences[currentIndex].text, Const.wavPath);
      await doPlayAudio(Const.wavPath);

      // 显示按钮
      setState(() {
        isPlaying = false;
        showButtons = true;
      });
    }
  }

  void _previousSentence() {
    setState(() {
      if (currentIndex > 0) {
        if (showAnswer) {
          showAnswer = false;
        } else {
          currentIndex--;
        }
      }
      showAnswer = false;
    });
    _saveProgress();
  }

  void _handleAnswer(bool isCorrect) {
    setState(() {
      if (isCorrect) {
        correctCount++;
        
        if (currentIndex < lesson!.sentences.length - 1) {
          currentIndex++;
          showAnswer = false;
        } else {
          // 如果是最后一句，显示结果并重置状态
          _showResultDialog();
        }
      } else {
        wrongCount++;
        // 错误按钮恢复原有功能，进入下一题
        if (currentIndex < lesson!.sentences.length - 1) {
          currentIndex++;
          showAnswer = false;
        } else {
          // 如果是最后一句，显示结果并重置状态
          _showResultDialog();
        }
      }
    });
    _saveProgress();
  }

  // 新增：重试当前题目的方法
  void _retryCurrentQuestion() {
    setState(() {
      showAnswer = false;
      showButtons = false;
    });
  }

  void _showResultDialog() {
    // 清除进度，因为测试已完成
    final currentAccount = AppContext.getCurrentAccount();
    UserSettingsMapper.saveSetting(
      currentAccount,
      'reading_quiz_last_progress',
      '0',
    );
    
    showDialog(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('测试完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('总题数: ${lesson!.sentences.length}'),
              const SizedBox(height: 8),
              Text('正确: $correctCount', style: TextStyle(color: Colors.green.shade300)),
              const SizedBox(height: 8),
              Text('错误: $wrongCount', style: TextStyle(color: Colors.red.shade200)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isStarted = false; // 返回选择课程界面
                });
              },
              child: const Text('返回选择'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartLesson(); // 重新开始当前课程
              },
              child: const Text('重新开始'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('选择课程'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: () {
              showChooseLessonDialog(context, lessons, _selectLesson);
            },
          ),
          if (lesson != null) ...[
            const SizedBox(height: 20),
            Text(
              '当前选择: ${lesson!.title}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
            if (hasLastProgress) ...[
              Text(
                '发现上次未完成的测试 (进度: ${currentIndex + 1}/${lesson!.sentences.length})',
                style: const TextStyle(color: Colors.orange, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('继续上次'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onPressed: _continueLastTest,
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新开始'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onPressed: _startLesson,
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始测试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: _startLesson,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    return GestureDetector(
      onTap: _nextSentence,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lesson!.sentences[currentIndex].textCn,
                        style: const TextStyle(fontSize: 36.0, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (showAnswer) ...[
                        Text(
                          lesson!.sentences[currentIndex].text,
                          style: const TextStyle(fontSize: 36.0, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (showButtons && !isPlaying) ...[  // 只在播放结束后显示按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => _handleAnswer(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  padding: const EdgeInsets.all(20),
                                  shape: const CircleBorder(),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 40),
                              ElevatedButton(
                                onPressed: () => _handleAnswer(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade300,
                                  padding: const EdgeInsets.all(20),
                                  shape: const CircleBorder(),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 40),
                              ElevatedButton(
                                onPressed: _retryCurrentQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade300,
                                  padding: const EdgeInsets.all(20),
                                  shape: const CircleBorder(),
                                ),
                                child: const Icon(
                                  Icons.replay,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: currentIndex > 0 || showAnswer ? _previousSentence : null,
                ),
                Text(
                  '正确: $correctCount  错误: $wrongCount',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _restartLesson,
                  tooltip: '重新开始',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Const.lightColor,
        title: const Text('课文翻译测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              showChooseLessonDialog(context, lessons, _selectLesson);
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              showEditFavourSentence(context, lessons);
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade800,
      body: !isStarted ? _buildStartScreen() : _buildQuizScreen(),
    );
  }
}
