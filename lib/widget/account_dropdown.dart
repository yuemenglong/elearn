import 'package:flutter/material.dart';
import '../db/account.dart';
import '../context/context.dart';
import '../page/star_page.dart';

class AccountDropdown extends StatefulWidget {
  const AccountDropdown({super.key});

  @override
  State<AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<AccountDropdown> {
  Account? selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await AccountMapper.selectList();
    setState(() {
      selectedAccount = accounts.firstWhere(
        (account) => account.name == AppContext.account.name,
        orElse: () => accounts.first,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Account>>(
      future: AccountMapper.selectList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final accounts = snapshot.data!;
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: () {
                Navigator.pushNamed(context, '/star');
              },
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: DropdownButton<Account>(
            value: selectedAccount,
            isExpanded: true,
            items: accounts.map((Account account) {
              return DropdownMenuItem<Account>(
                value: account,
                child: Text(account.name),
              );
            }).toList(),
            onChanged: (Account? newValue) {
              setState(() {
                selectedAccount = newValue;
                AppContext.account = newValue!;
              });
            },
              ),
            ),
          ],
        );
      },
    );
  }
}
