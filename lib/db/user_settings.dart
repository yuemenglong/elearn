import 'db.dart';

class UserSettings {
  String? id;
  String? account;
  String? settingKey;
  String? settingValue;
  DateTime? updatedAt;

  UserSettings({
    this.id,
    this.account,
    this.settingKey,
    this.settingValue,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account': account,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  static UserSettings fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'],
      account: map['account'],
      settingKey: map['setting_key'],
      settingValue: map['setting_value'],
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }
}

class UserSettingsMapper {
  static const String tableName = 'user_settings';

  static String getCreateTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        account TEXT NOT NULL,
        setting_key TEXT NOT NULL,
        setting_value TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(account, setting_key)
      )
    ''';
  }

  // 生成设置ID
  static String generateSettingId(String account, String settingKey) {
    return '${account}_$settingKey';
  }

  // 保存或更新设置
  static Future<void> saveSetting(String account, String settingKey, String settingValue) async {
    final setting = UserSettings(
      id: generateSettingId(account, settingKey),
      account: account,
      settingKey: settingKey,
      settingValue: settingValue,
      updatedAt: DateTime.now(),
    );

    const sql = '''
      INSERT OR REPLACE INTO $tableName 
      (id, account, setting_key, setting_value, updated_at) 
      VALUES (?, ?, ?, ?, ?)
    ''';
    
    await Db.execute(sql, [
      setting.id!,
      setting.account!,
      setting.settingKey!,
      setting.settingValue!,
      setting.updatedAt!.millisecondsSinceEpoch,
    ]);
  }

  // 获取设置值
  static Future<String?> getSetting(String account, String settingKey) async {
    const sql = '''
      SELECT setting_value FROM $tableName 
      WHERE account = ? AND setting_key = ?
    ''';
    
    final results = await Db.query(sql, [account, settingKey]);
    
    if (results.isNotEmpty) {
      return results.first['setting_value'] as String?;
    }
    
    return null;
  }

  // 获取用户的所有设置
  static Future<Map<String, String>> getAllSettings(String account) async {
    const sql = '''
      SELECT setting_key, setting_value FROM $tableName 
      WHERE account = ?
    ''';
    
    final results = await Db.query(sql, [account]);
    
    Map<String, String> settings = {};
    for (final row in results) {
      settings[row['setting_key'] as String] = row['setting_value'] as String;
    }
    
    return settings;
  }

  // 删除设置
  static Future<void> deleteSetting(String account, String settingKey) async {
    const sql = '''
      DELETE FROM $tableName 
      WHERE account = ? AND setting_key = ?
    ''';
    
    await Db.execute(sql, [account, settingKey]);
  }

  // 清理用户的所有设置
  static Future<void> clearUserSettings(String account) async {
    const sql = '''
      DELETE FROM $tableName WHERE account = ?
    ''';
    
    await Db.execute(sql, [account]);
  }
} 