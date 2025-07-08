import 'package:flutter/material.dart';
import '../const/const.dart';
import '../lesson/lesson.dart';
import '../db/star.dart';
import '../context/context.dart';

const TextStyle textStyle = TextStyle(color: Colors.white, fontSize: 20);
const double tableWidth = 800;

class StarPage extends StatefulWidget {
  const StarPage({super.key});

  @override
  State<StarPage> createState() => _StarPageState();
}

class _StarPageState extends State<StarPage> {
  List<Lesson> lessons = [];
  List<Star> stars = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载 lesson 与 star 数据
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final lessonsData = await LessonStore.getLessons();
      final account = AppContext.getCurrentAccount();
      final starsData = await StarMapper.selectList(account);
      setState(() {
        lessons = lessonsData;
        stars = starsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  /// 在双击星星后调用，更新对应的记录后刷新数据。
  Future<void> _toggleStar({required bool hasStar, required int lessonNo, required String type}) async {
    final star = Star()
      ..account = AppContext.getCurrentAccount()
      ..type = type
      ..lessonNo = lessonNo
      ..time = DateTime.now();

    if (hasStar) {
      await StarMapper.delete(star);
    } else {
      await StarMapper.upsert(star);
    }
    // 数据更新后，重新加载数据，刷新页面
    await _loadData();
  }

  /// 计算总的星星数量（注意：某个课程一种类型的测验只计一次）
  int _countUniqueStars() {
    // 如果数据库中已经确保一条记录只记录一次star，那么只需返回stars的长度即可
    return stars.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Const.lightColor,
        title: const Text('我的记录', style: TextStyle(fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text('Error: $errorMessage', style: textStyle))
                : lessons.isEmpty
                    ? const Center(child: Text('No lessons found', style: textStyle))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左上角增加星星计数的显示
                          Text(
                            'Star Count: ${_countUniqueStars()}',
                            style: textStyle,
                          ),
                          const SizedBox(height: 16.0),
                          // 下面显示课程表
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Center(
                                child: LessonTable(
                                  lessons: lessons,
                                  stars: stars,
                                  onToggleStar: _toggleStar,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

/// LessonTable 改为 StatelessWidget，通过外部传入的 onToggleStar 回调通知父组件执行刷新操作。
class LessonTable extends StatelessWidget {
  final List<Lesson> lessons;
  final List<Star> stars;

  /// 当双击星星时，调用回调，并传入当前状态以及对应 lessonNo 与类型
  final Future<void> Function({required bool hasStar, required int lessonNo, required String type}) onToggleStar;

  const LessonTable({
    super.key,
    required this.lessons,
    required this.stars,
    required this.onToggleStar,
  });

  bool _hasStar(int lessonNo, String type) {
    return stars.any((star) => star.lessonNo == lessonNo && star.type == type);
  }

  Widget _buildStarCellWrapper(bool hasStar, int lessonNo, String type) {
    return GestureDetector(
      onDoubleTap: () async {
        await onToggleStar(hasStar: hasStar, lessonNo: lessonNo, type: type);
      },
      child: _buildStarCell(hasStar),
    );
  }

  Widget _buildStarCell(bool hasStar) {
    return Center(
      child: Icon(
        Icons.star,
        color: hasStar ? Colors.yellow : Colors.grey,
        size: 28,
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      color: Colors.black.withAlpha(50),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('Lesson', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('英文转中文', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('中文转英文', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('终极测验', style: textStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '${lesson.number}. ${lesson.title}',
              style: textStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildStarCellWrapper(_hasStar(lesson.number, 'en2cn'), lesson.number, 'en2cn'),
          ),
          Expanded(
            flex: 2,
            child: _buildStarCellWrapper(_hasStar(lesson.number, 'cn2en'), lesson.number, 'cn2en'),
          ),
          Expanded(
            flex: 2,
            child: _buildStarCellWrapper(_hasStar(lesson.number, 'final'), lesson.number, 'final'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: lessons.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeaderRow();
            } else {
              final lesson = lessons[index - 1];
              return _buildDataRow(lesson);
            }
          },
        ),
      ),
    );
  }
}
