import 'package:flutter/material.dart';

import '../db/favour_sentence.dart';
import '../lesson/lesson.dart';
import 'dart:async';

/// 弹窗方法
///
/// [lessons]：所有课程数据
/// [onConfirm]：可选的回调，你可以在关闭时，将“已收藏”的信息或其他需要的信息回传给调用者
void showEditFavourSentence(
  BuildContext context,
  List<Lesson> lessons, {
  Function()? onConfirm, // 如果需要回传东西，可以改成 Function(List<FavourSentence>) 等
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return EditFavourSentence(
        lessons: lessons,
        onConfirm: onConfirm,
      );
    },
  );
}

/// 显示所有课程所有句子的对话框
class EditFavourSentence extends StatefulWidget {
  final List<Lesson> lessons;
  final Function()? onConfirm;

  const EditFavourSentence({
    Key? key,
    required this.lessons,
    this.onConfirm,
  }) : super(key: key);

  @override
  State<EditFavourSentence> createState() => _EditFavourSentenceState();
}

class _EditFavourSentenceState extends State<EditFavourSentence> {
  /// 存放已经收藏的句子对应的 id（ lessonNo-index ）
  late Set<String> _favourIds = {};

  /// 是否正在加载
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourSentences();
  }

  /// 从数据库加载已收藏的句子
  Future<void> _loadFavourSentences() async {
    try {
      final list = await FavourSentenceMapper.selectList();
      setState(() {
        _favourIds = list.map((fs) => fs.id).toSet();
        _loading = false;
      });
    } catch (e) {
      // 加载失败处理
      debugPrint("加载 FavourSentence 失败: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  /// 用户勾选复选框
  Future<void> _onCheckChanged(bool? newValue, String id, String lessonNo, int index) async {
    if (newValue == true) {
      // 如果勾选，执行 upsert
      final fs = FavourSentence()
        ..id = id
        ..lessonNo = lessonNo
        ..itemIndex = index;
      await FavourSentenceMapper.upsert(fs);
      setState(() {
        _favourIds.add(id);
      });
    } else {
      // 如果取消勾选，执行 delete
      await FavourSentenceMapper.deleteById(id);
      setState(() {
        _favourIds.remove(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 16,
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 400,
        height: 600, // 如果想自适应内容，可去掉 height
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "编辑收藏的句子",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildSentenceList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // 如果需要将选中的收藏句子信息回传，可以在这里处理
                          widget.onConfirm?.call();
                          Navigator.of(context).pop();
                        },
                        child: const Text("关闭"),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  /// 构建所有课程所有句子的列表
  Widget _buildSentenceList() {
    return ListView.builder(
      itemCount: widget.lessons.length,
      itemBuilder: (context, lessonIndex) {
        final lesson = widget.lessons[lessonIndex];

        // 将每个 lesson 包一层 ExpansionTile，里面列出所有句子
        return ExpansionTile(
          title: Text("Lesson ${lesson.number} - ${lesson.title}"),
          subtitle: Text(lesson.titleCn),
          children: [
            // 如果没有句子，提示一下
            if (lesson.sentences.isEmpty)
              const ListTile(
                title: Text("无句子"),
              )
            else
              Column(
                children: List.generate(lesson.sentences.length, (index) {
                  final sentence = lesson.sentences[index];
                  final id = "${lesson.number}-$index";
                  final isFavourite = _favourIds.contains(id);

                  return CheckboxListTile(
                    title: Text(sentence.text),
                    subtitle: Text(sentence.textCn),
                    value: isFavourite,
                    onChanged: (bool? newValue) {
                      _onCheckChanged(newValue, id, "${lesson.number}", index);
                    },
                  );
                }),
              ),
          ],
        );
      },
    );
  }
}
