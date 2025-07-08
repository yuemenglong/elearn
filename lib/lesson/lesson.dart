import 'dart:io';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

class Lesson {
  int number = 0;
  String title = "";
  String titleCn = "";
  List<Word> words = [];
  List<Sentence> sentences = [];

  Lesson({
    required this.number,
    required this.title,
    required this.titleCn,
    required this.words,
    required this.sentences,
  });

  Lesson dup() {
    var ret = Lesson(
      number: this.number,
      title: this.title,
      titleCn: this.titleCn,
      // 深拷贝 List，复制每个元素
      words: this.words.toList(),
      sentences: this.sentences.toList(),
    );
    ret.words.shuffle();
    ret.sentences.shuffle();
    return ret;
  }
}

class Sentence {
  String text = "";
  String textCn = "";

  Sentence({required this.text, required this.textCn});
}

class Word {
  String text = "";
  String textCn = "";

  Word({required this.text, required this.textCn});
}

class LessonStore {
  static List<Lesson> _lessons = [];

  static Future<List<Lesson>> getLessons() async {
    if (_lessons.isEmpty) {
      _lessons = await loadLessons();
    }

    return _lessons;
  }
}

Future<List<Lesson>> loadLessons() async {
  // 通过 bundle 打开 assets/files.txt 并读取内容
  final filesContent = await rootBundle.loadString('assets/files.txt');

  // 解析文件内容，获取每个 XML 文件的路径（逐行读取）
  final filePaths = filesContent.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);

  // 遍历路径，加载并解析每个 XML 文件
  final lessons = await Future.wait(filePaths.map((path) async {
    final xml = await rootBundle.loadString('assets/$path'); // 加载 XML 文件内容
    return loadLessonFromXml(xml); // 调用解析方法
  }));
  // sort by number
  lessons.sort((a, b) => a.number.compareTo(b.number));
  return lessons; // 返回解析结果
}

Future<Lesson> loadLessonFromXml(String xml) async {
  try {
    final document = XmlDocument.parse(xml);

    final lessonElement = document.getElement('lesson');
    if (lessonElement == null) {
      throw Exception('Invalid XML: Missing <lesson> root element');
    }

    // Parse number, title, and titleCn
    final number = int.tryParse(lessonElement.getElement('number')?.text ?? '0') ?? 0;
    final title = lessonElement.getElement('title')?.text ?? '';
    final titleCn = lessonElement.getElement('titleCn')?.text ?? '';

    // Parse words
    final words = lessonElement.getElement('words')?.findElements('word').map((wordElement) {
          final text = wordElement.getElement('text')?.text ?? '';
          final textCn = wordElement.getElement('textCn')?.text ?? '';
          return Word(text: text, textCn: textCn);
        }).toList() ??
        [];

    // Parse sentences
    final sentences = lessonElement.getElement('sentences')?.findElements('sentence').map((sentenceElement) {
          final text = sentenceElement.getElement('text')?.text ?? '';
          final textCn = sentenceElement.getElement('textCn')?.text ?? '';
          return Sentence(text: text, textCn: textCn);
        }).toList() ??
        [];

    // Return the Lesson object
    return Lesson(
      number: number,
      title: title,
      titleCn: titleCn,
      words: words,
      sentences: sentences,
    );
  } catch (e) {
    print("解析失败: $xml");
    rethrow;
  }
}
