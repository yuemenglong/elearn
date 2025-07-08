import 'package:record_example/db/account.dart';

class AppContext {
  static late Account account;

  static Future<void> init() async {
    var accounts = await AccountMapper.selectList();
    account = accounts.where((x) => x.name == "岳子元").first;
  }

  static getCurrentAccount() {
    return account.name;
  }
}
