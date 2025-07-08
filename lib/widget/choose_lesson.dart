import 'package:flutter/material.dart';
import '../const/const.dart';

// 如果要使用 firstWhereOrNull，需要引入 collection 包
import 'package:collection/collection.dart';

import '../lesson/lesson.dart';
import '../db/favour_sentence.dart';

class ChooseLesson extends StatefulWidget {
  final List<Lesson> lessons;
  final Function(Lesson) onConfirm;

  const ChooseLesson({
    super.key,
    required this.lessons,
    required this.onConfirm,
  });

  @override
  State<ChooseLesson> createState() => _ChooseLessonState();
}

class _ChooseLessonState extends State<ChooseLesson> {
  /// 用来展示在列表中的所有“可选课程”
  /// 注意，这里会在加载收藏句子后，把一个“收藏课程”插入到最前面
  List<Lesson> _lessonsWithFav = [];

  /// 当前选中的 Lesson
  Lesson? _selectedLesson;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// 异步初始化数据：
  /// 1. 从数据库获取所有收藏句子
  /// 2. 生成一个“收藏课程”（可自定义 number = -1）
  /// 3. 将“收藏课程”插入到所有课程列表的最前面
  Future<void> _initData() async {
    // 获取所有收藏记录
    final favourList = await FavourSentenceMapper.selectList();

    // 先把原有的课程复制一下
    List<Lesson> tempLessons = List.from(widget.lessons);

    // 如果收藏列表不为空，则构造一个“收藏课”
    if (favourList.isNotEmpty) {
      // 创建一个模拟的 Lesson，课程编号可自定义为 -1
      Lesson favouriteLesson = Lesson(
        number: -1,
        title: "我的收藏",
        titleCn: "",
        // 中文标题可自行定义
        words: [],
        sentences: [],
      );

      // favourlist按照lessonNo和itemIndex排序
      favourList.sort((a, b) {
        if (a.lessonNo == b.lessonNo) {
          return a.itemIndex.compareTo(b.itemIndex);
        }
        return a.lessonNo.compareTo(b.lessonNo);
      });

      // 遍历收藏的每条记录，从原课程数据中找到对应句子，组装到收藏课中
      for (var fs in favourList) {
        // fs.lessonNo 是字符串，需要转 int
        final int? lessonNo = int.tryParse(fs.lessonNo);
        if (lessonNo == null) continue;

        // 在 widget.lessons 中找到对应课程
        final originLesson = widget.lessons.firstWhereOrNull((l) => l.number == lessonNo);
        if (originLesson == null) continue;

        // 确保下标合法
        if (fs.itemIndex < 0 || fs.itemIndex >= originLesson.sentences.length) continue;

        // 将对应的句子加到“我的收藏”课程里
        favouriteLesson.sentences.add(originLesson.sentences[fs.itemIndex]);
      }
      // 将“收藏课程”插到最前面
      tempLessons.insert(0, favouriteLesson);
    }

    setState(() {
      _lessonsWithFav = tempLessons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 圆角
      ),
      elevation: 16, // 阴影
      backgroundColor: Colors.white, // 背景颜色
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 内边距
        child: Column(
          mainAxisSize: MainAxisSize.min, // 使 Column 高度根据内容自适应
          children: [
            const Text(
              "选择课程",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16), // 添加间距
            Container(
              constraints: const BoxConstraints(maxHeight: 600), // 限制列表的最大高度
              child: _lessonsWithFav.isEmpty
                  ? const Center(child: Text("暂无课程", style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      shrinkWrap: true, // 使 ListView 高度根据内容自适应
                      itemCount: _lessonsWithFav.length,
                      itemBuilder: (context, index) {
                        final lesson = _lessonsWithFav[index];

                        // 如果 lesson.number == -1，表示“我的收藏”
                        final lessonTitle = lesson.number == -1
                            ? lesson.title // "我的收藏"
                            : "Lesson ${lesson.number} : ${lesson.title}";

                        return ListTile(
                          title: Text(lessonTitle),
                          // 可根据编号 -1 的课加特殊图标
                          leading: lesson.number == -1 ? const Icon(Icons.favorite) : null,
                          selected: _selectedLesson == lesson,
                          onTap: () {
                            setState(() {
                              _selectedLesson = lesson;
                            });
                            widget.onConfirm(lesson); // 回调
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 对外提供的调用示例
void showChooseLessonDialog(BuildContext context, List<Lesson> lessons, Function(Lesson) onConfirm) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ChooseLesson(
        lessons: lessons,
        onConfirm: onConfirm,
      );
    },
  );
}
