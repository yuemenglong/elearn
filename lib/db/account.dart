import 'db.dart';

class Account {
  String name = "";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class AccountMapper {
  static String getCreateTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS account (
        name TEXT PRIMARY KEY
      )
    ''';
  }

  static Future<void> init() async {
    // 写入岳子萱/岳子元两条数据
    await AccountMapper.upsert(Account()..name = "岳子萱");
    await AccountMapper.upsert(Account()..name = "岳子元");
  }

  static Future<Account> upsert(Account account) async {
    final db = await Db.database;
    await db.rawInsert('''
      INSERT OR REPLACE INTO account (name)
      VALUES (?)
    ''', [account.name]);
    return account;
  }

  static Future<List<Account>> selectList() async {
    final db = await Db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM account
    ''');
    return List.generate(maps.length, (i) {
      return Account()..name = maps[i]['name'];
    });
  }

  static Future<Account> select() async {
    final db = await Db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM account
    ''');
    if (maps.length == 0) {
      return Account();
    }
    return Account()..name = maps[0]['name'];
  }

  static Future<void> delete() async {
    final db = await Db.database;
    await db.rawDelete('''
      DELETE FROM account
    ''');
  }
}
