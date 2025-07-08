import 'package:flutter/material.dart';
import 'package:record_example/page/quiz_store.dart';
import '../context/context.dart';
import '../db/star.dart';
import '../db/user_settings.dart';
import '../lesson/lesson.dart';
import '../const/const.dart';
import '../widget/choose_lesson.dart'; // 确保有这个组件
import '../widget/edit_favour_sentence.dart'; // 如果需要编辑收藏功能

// 修改：将回答历史记录的数据结构中 isCorrect 属性设置为可变变量
class AnswerHistoryEntry {
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  bool isCorrect; // 可修改

  AnswerHistoryEntry({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });
}

class QuizPage extends StatefulWidget {
  final bool isCn2En;

  const QuizPage({super.key, required this.isCn2En});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Lesson>? _lessons;
  Lesson? _selectedLesson; // 当前选择的课程
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isStart = false;
  bool _isPreloading = false; // 添加预加载状态
  late QuizStore _store;
  List<String> _options = [];

  // 统计得分（初始测验计数，后续不会改变星星计算逻辑）
  int _correctCount = 0;
  int _wrongCount = 0;

  // 回答历史记录
  List<AnswerHistoryEntry> _answerHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  // 加载所有课程
  void _loadLessons() async {
    final lessons = await LessonStore.getLessons();
    
    // 获取当前用户账号
    final currentAccount = AppContext.getCurrentAccount();
    
    // 获取上次选择的课程
    final lastSelectedLessonNo = await UserSettingsMapper.getSetting(
      currentAccount, 
      'quiz_last_lesson_${widget.isCn2En ? 'cn2en' : 'en2cn'}'
    );
    
    Lesson selectedLesson = lessons.last; // 默认使用最后一个课程
    
    if (lastSelectedLessonNo != null) {
      // 尝试找到上次选择的课程
      try {
        final lessonNo = int.parse(lastSelectedLessonNo);
        final foundLesson = lessons.where((lesson) => lesson.number == lessonNo).firstOrNull;
        if (foundLesson != null) {
          selectedLesson = foundLesson;
          print("恢复上次选择的课程: ${selectedLesson.title}");
        } else {
          print("无法找到上次选择的课程，使用默认课程");
        }
      } catch (e) {
        print("解析课程号失败，使用默认课程: $e");
      }
    }
    
    setState(() {
      _lessons = lessons;
      _selectedLesson = selectedLesson.dup();
    });
  }

  // 显示选择课程对话框
  void _showChooseLessonDialog() {
    if (_lessons == null || _lessons!.isEmpty) return;
    showChooseLessonDialog(context, _lessons!, (Lesson selected) async {
      // 保存用户选择的课程
      final currentAccount = AppContext.getCurrentAccount();
      await UserSettingsMapper.saveSetting(
        currentAccount,
        'quiz_last_lesson_${widget.isCn2En ? 'cn2en' : 'en2cn'}',
        selected.number.toString(),
      );
      
      setState(() {
        _selectedLesson = selected.dup();
        _correctCount = 0;
        _wrongCount = 0;
        _isStart = false;
        _isPreloading = false; // 重置预加载状态
        // 每次换课程时清空历史记录（可选）
        _answerHistory.clear();
      });
    });
  }

  // 处理用户选择的答案
  void _handleAnswer(String answer) {
    if (_selectedAnswer != null) return; // 防止重复选择
    final correctAnswer = _store.getCurrentAnswer();

    // 保存答案记录
    _answerHistory.add(
      AnswerHistoryEntry(
        question: _store.getCurrentQuestion(),
        selectedAnswer: answer,
        correctAnswer: correctAnswer,
        isCorrect: answer == correctAnswer,
      ),
    );

    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      if (answer == correctAnswer) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_selectedAnswer != _store.getCurrentAnswer()) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      setState(() {
        _options = [];
        _showResult = false;
        _selectedAnswer = null;
      });

      _store.moveNext();
      var options = await _store.getCurrentOptions();
      setState(() {
        _options = options;
      });
      if (_store.isFinish()) {
        setState(() {
          _isStart = false;
        });
        _showScoreDialog();
      }
    });
  }

  // 显示得分对话框
  void _showScoreDialog() {
    // 如果全对，记录star，此处用的是 _correctCount 原始统计数据，不受后续标记影响
    if (_correctCount >= _store.totalCount()) {
      final star = Star()
        ..account = AppContext.getCurrentAccount()
        ..type = widget.isCn2En ? "cn2en" : "en2cn"
        ..lessonNo = _selectedLesson!.number
        ..time = DateTime.now();
      StarMapper.upsert(star);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('测验完成'),
        content: Text('正确：$_correctCount\n错误：$_wrongCount'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示回答历史对话框
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('回答历史'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _answerHistory.isEmpty
                ? const Center(child: Text('暂无历史记录'))
                : ListView.builder(
                    itemCount: _answerHistory.length,
                    itemBuilder: (context, index) {
                      final entry = _answerHistory[index];
                      return ListTile(
                        title: Text(
                          entry.question,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '你的回答：${entry.selectedAnswer}   正确答案：${entry.correctAnswer}',
                                style: TextStyle(
                                  color: entry.isCorrect ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            // 如果当前记录判定为错误，则显示"标记正确"按钮
                            if (!entry.isCorrect)
                              TextButton(
                                onPressed: () {
                                  // 用户点击标记正确，更新该题状态及界面显示的正确和错误计数
                                  setState(() {
                                    // 如果之前状态为错误，则更新计数
                                    _wrongCount = (_wrongCount > 0 ? _wrongCount - 1 : 0);
                                    _correctCount++;
                                    entry.isCorrect = true;
                                  });
                                },
                                child: const Text('标记正确'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 开始测验的方法
  Future<void> _startQuiz() async {
    if (_selectedLesson == null) {
      _showChooseLessonDialog();
      return;
    }

    setState(() {
      _isPreloading = true;
      _correctCount = 0;
      _wrongCount = 0;
      _options = [];
      _answerHistory.clear();
    });

    try {
      _store = QuizStore(
        lesson: _selectedLesson!.dup(),
        isCn2En: widget.isCn2En,
      );

      // 预加载所有选项
      await _store.preloadAllOptions();

      // 获取第一题的选项
      final firstOptions = await _store.getCurrentOptions();

      setState(() {
        _isPreloading = false;
        _isStart = true;
        _options = firstOptions;
      });
    } catch (e) {
      setState(() {
        _isPreloading = false;
      });
      
      // 显示错误对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('加载失败'),
          content: Text('预加载选项时出错：$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有选择课程，显示提示信息
    if (_selectedLesson == null) {
      return Scaffold(
        backgroundColor: Const.backgroundColor,
        appBar: AppBar(
          title: const Text('小测验'),
          backgroundColor: Const.lightColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showHistoryDialog,
            )
          ],
        ),
        body: const Center(
          child: Text(
            '请选择课程并点击"开始测验"按钮',
            style: TextStyle(fontSize: 24.0, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        floatingActionButton: _buildFloatingButtons(),
      );
    }

    // 如果正在预加载，显示加载界面
    if (_isPreloading) {
      return Scaffold(
        backgroundColor: Const.backgroundColor,
        appBar: AppBar(
          title: Text('小测验 - ${_selectedLesson!.title}'),
          backgroundColor: Const.lightColor,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                '正在加载测验选项...',
                style: TextStyle(fontSize: 24.0, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                '首次加载可能需要一些时间',
                style: TextStyle(fontSize: 16.0, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 如果选中了课程，但还没有开始测验，显示等待开始的界面
    if (!_isStart) {
      return Scaffold(
        backgroundColor: Const.backgroundColor,
        appBar: AppBar(
          title: Text('小测验 - ${_selectedLesson!.title}'),
          backgroundColor: Const.lightColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showHistoryDialog,
            )
          ],
        ),
        body: const Center(
          child: Text(
            '准备好了吗？点击"开始测验"按钮开始！',
            style: TextStyle(fontSize: 24.0, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        floatingActionButton: _buildFloatingButtons(),
      );
    }

    // 显示测验内容
    return Scaffold(
      backgroundColor: Const.backgroundColor,
      appBar: AppBar(
        title: Text('小测验 - ${_selectedLesson!.title}'),
        backgroundColor: Const.lightColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
          )
        ],
      ),
      body: Column(
        children: [
          // 显示当前句子的中文翻译
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _store.getCurrentQuestion(),
              style: const TextStyle(fontSize: 48.0, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          // 显示选项列表
          Expanded(
            child: ListView.builder(
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                bool isCorrect = option == _store.getCurrentAnswer();
                bool isSelected = option == _selectedAnswer;
                Color? tileColor;

                if (_showResult) {
                  if (isCorrect) {
                    tileColor = Colors.green[100];
                  } else if (isSelected) {
                    tileColor = Colors.red[100];
                  } else {
                    tileColor = Const.backgroundColor;
                  }
                } else {
                  tileColor = Const.backgroundColor;
                }

                return ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(fontSize: 36.0, color: Colors.white),
                  ),
                  onTap: _selectedAnswer == null ? () => _handleAnswer(option) : null,
                  tileColor: tileColor,
                );
              },
            ),
          ),
          // 显示结果提示
          if (_showResult)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _selectedAnswer == _store.getCurrentAnswer() ? '正确！' : '错误！',
                style: TextStyle(
                  color: _selectedAnswer == _store.getCurrentAnswer() ? Colors.green : Colors.red,
                  fontSize: 36,
                ),
              ),
            ),
          // 显示当前得分
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '正确：$_correctCount  错误：$_wrongCount',
              style: const TextStyle(fontSize: 20.0, color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  // 构建右下角的三个浮动按钮
  Widget _buildFloatingButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 开始测验按钮
          FloatingActionButton.extended(
            heroTag: 'startQuiz',
            onPressed: _isPreloading ? null : _startQuiz, // 预加载时禁用按钮
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始测验'),
          ),
          const SizedBox(height: 16),
          // 选择课程按钮
          FloatingActionButton.extended(
            heroTag: 'chooseLesson',
            onPressed: _isPreloading ? null : _showChooseLessonDialog, // 预加载时禁用按钮
            icon: const Icon(Icons.menu_book),
            label: const Text('选择课程'),
          ),
          const SizedBox(height: 16),
          // 编辑收藏按钮（如果有收藏功能）
          FloatingActionButton.extended(
            heroTag: 'editFavorites',
            onPressed: _isPreloading ? null : () {
              if (_lessons != null) {
                showEditFavourSentence(context, _lessons!);
              }
            }, // 预加载时禁用按钮
            icon: const Icon(Icons.favorite),
            label: const Text('编辑收藏'),
          ),
        ],
      ),
    );
  }
}
