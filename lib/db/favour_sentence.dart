import 'db.dart';

class FavourSentence {
  String id = ""; // lessonNo+"-"+index
  String lessonNo = "";
  int itemIndex = 0;
}

class FavourSentenceMapper {
  static String getCreateTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS favour_sentence (
        id TEXT PRIMARY KEY,
        lesson_no TEXT,
        item_index INTEGER
      )
    ''';
  }

  static Future<FavourSentence> upsert(FavourSentence fs) async {
    if (fs.id == "") {
      fs.id = "${fs.lessonNo}-${fs.itemIndex}";
    }
    final db = await Db.database;
    await db.rawInsert('''
      INSERT OR REPLACE INTO favour_sentence (id, lesson_no, item_index)
      VALUES (?, ?, ?)
    ''', [fs.id, fs.lessonNo, fs.itemIndex]);
    return fs;
  }

  static Future<List<FavourSentence>> selectList() async {
    final db = await Db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM favour_sentence
    ''');
    return List.generate(maps.length, (i) {
      return FavourSentence()
        ..id = maps[i]['id']
        ..lessonNo = maps[i]['lesson_no']
        ..itemIndex = maps[i]['item_index'];
    });
  }

  static Future<void> deleteById(String id) async {
    final db = await Db.database;
    await db.rawDelete('''
      DELETE FROM favour_sentence WHERE id = ?
    ''', [id]);
  }
}
