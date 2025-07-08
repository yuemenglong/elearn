import 'package:record_example/db/account.dart';
import 'package:record_example/db/favour_sentence.dart';
import 'package:record_example/db/star.dart';
import 'package:record_example/db/quiz_cache.dart';
import 'package:record_example/db/user_settings.dart';
import 'package:record_example/util/cache_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

class Db {
  static Database? _database;

  // 获取数据库实例
  static Future<Database> get database async {
    if (_database == null) {
      throw Exception("Database has not been initialized. Call Db.init() first.");
    }
    return _database!;
  }

  // 初始化数据库
  static Future<void> init() async {
    // 如果是桌面环境，确保初始化 FFI 工厂
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 使用新的缓存工具类获取数据库路径
    String path = await CacheUtils.getDatabasePath();
    _database = await openDatabase(
      path,
      version: 3, // 增加版本号以支持新表
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _initData();
  }

  static Future<void> _initData() async {
    await AccountMapper.init();
  }

  // 创建数据库表
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(FavourSentenceMapper.getCreateTableSql());
    await db.execute(AccountMapper.getCreateTableSql());
    await db.execute(StarMapper.getCreateTableSql());
    await db.execute(QuizCacheMapper.getCreateTableSql());
    await db.execute(UserSettingsMapper.getCreateTableSql());
  }

  // 数据库升级
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加quiz_cache表
      await db.execute(QuizCacheMapper.getCreateTableSql());
    }
    if (oldVersion < 3) {
      // 添加user_settings表
      await db.execute(UserSettingsMapper.getCreateTableSql());
    }
  }

  // 执行查询（带参数）
  static Future<List<Map<String, dynamic>>> query(String sql, List<Object> params) async {
    final db = await database;
    return await db.rawQuery(sql, params);
  }

  // 执行SQL语句（带参数，如INSERT, UPDATE, DELETE）
  static Future<int> execute(String sql, List<Object> params) async {
    final db = await database;
    return await db.rawInsert(sql, params);
  }

  // 关闭数据库
  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
