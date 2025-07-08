import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'db.dart';

class QuizCache {
  String? id;
  String? question;
  String? answer;
  String? type; // 'en2cn' 或 'cn2en'
  String? options; // JSON字符串，存储选项数组
  DateTime? createdAt;

  QuizCache({
    this.id,
    this.question,
    this.answer,
    this.type,
    this.options,
    this.createdAt,
  });

  // 生成缓存键，基于问题、答案和类型的哈希值
  static String generateCacheKey(String question, String answer, String type) {
    final input = '$question|$answer|$type';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'type': type,
      'options': options,
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }

  static QuizCache fromMap(Map<String, dynamic> map) {
    return QuizCache(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      type: map['type'],
      options: map['options'],
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
    );
  }

  List<String> getOptionsAsList() {
    if (options == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(options!);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  void setOptionsFromList(List<String> optionsList) {
    options = jsonEncode(optionsList);
  }
}

class QuizCacheMapper {
  static const String tableName = 'quiz_cache';

  static String getCreateTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        type TEXT NOT NULL,
        options TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''';
  }

  // 插入或更新缓存
  static Future<void> upsert(QuizCache cache) async {
    cache.id = QuizCache.generateCacheKey(
      cache.question!, 
      cache.answer!, 
      cache.type!
    );
    cache.createdAt = DateTime.now();

    const sql = '''
      INSERT OR REPLACE INTO $tableName 
      (id, question, answer, type, options, created_at) 
      VALUES (?, ?, ?, ?, ?, ?)
    ''';
    
    await Db.execute(sql, [
      cache.id!,
      cache.question!,
      cache.answer!,
      cache.type!,
      cache.options!,
      cache.createdAt!.millisecondsSinceEpoch,
    ]);
  }

  // 根据问题、答案和类型查找缓存
  static Future<QuizCache?> findByKey(String question, String answer, String type) async {
    final cacheKey = QuizCache.generateCacheKey(question, answer, type);
    
    const sql = '''
      SELECT * FROM $tableName WHERE id = ?
    ''';
    
    final results = await Db.query(sql, [cacheKey]);
    
    if (results.isNotEmpty) {
      return QuizCache.fromMap(results.first);
    }
    
    return null;
  }

  // 批量插入缓存
  static Future<void> batchUpsert(List<QuizCache> caches) async {
    final db = await Db.database;
    final batch = db.batch();
    
    for (final cache in caches) {
      cache.id = QuizCache.generateCacheKey(
        cache.question!, 
        cache.answer!, 
        cache.type!
      );
      cache.createdAt = DateTime.now();
      
      batch.rawInsert('''
        INSERT OR REPLACE INTO $tableName 
        (id, question, answer, type, options, created_at) 
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        cache.id!,
        cache.question!,
        cache.answer!,
        cache.type!,
        cache.options!,
        cache.createdAt!.millisecondsSinceEpoch,
      ]);
    }
    
    await batch.commit();
  }

  // 清理过期缓存（可选，比如清理30天前的缓存）
  static Future<void> cleanExpiredCache({int daysToKeep = 30}) async {
    final expiredTime = DateTime.now().subtract(Duration(days: daysToKeep));
    
    const sql = '''
      DELETE FROM $tableName WHERE created_at < ?
    ''';
    
    await Db.execute(sql, [expiredTime.millisecondsSinceEpoch]);
  }
} 