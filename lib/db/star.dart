import 'db.dart';

// type: "cn2en" / "en2cn" / "final"
// 中文->英文 / 英文->中文 / 终极测验
class Star {
  String account = "";
  String type = "";
  int lessonNo = 0;
  DateTime time = DateTime.now();
}

class StarMapper {
  static String getCreateTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS star (
        account TEXT,
        type TEXT,
        lesson_no INTEGER,
        time TEXT,
        PRIMARY KEY (account, type, lesson_no)
      )
    ''';
  }

  static Future<Star> upsert(Star star) async {
    final db = await Db.database;
    await db.rawInsert('''
      INSERT OR REPLACE INTO star (account, type, lesson_no, time)
      VALUES (?, ?, ?, ?)
    ''', [star.account, star.type, star.lessonNo, star.time.toIso8601String()]);
    return star;
  }

  static Future<List<Star>> selectList(String account) async {
    final db = await Db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM star WHERE account = ?
    ''', [account]);
    return List.generate(maps.length, (i) {
      return Star()
        ..account = maps[i]['account']
        ..type = maps[i]['type'] // Renamed from quiz_name to type
        ..lessonNo = maps[i]['lesson_no']
        ..time = DateTime.parse(maps[i]['time']);
    });
  }

  static Future<void> delete(star) async {
    final db = await Db.database;
    await db.rawDelete('''
      DELETE FROM star WHERE account = ? AND type = ? AND lesson_no = ?
    ''', [star.account, star.type, star.lessonNo]);
  }
}
