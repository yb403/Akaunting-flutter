import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/account_cubit.dart';
import '../../cubit/account_state.dart';
import '../../models/account.dart';

class AccountsListPage extends StatelessWidget {
  const AccountsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountCubit()..fetchAccounts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
        ),
        body: BlocBuilder<AccountCubit, AccountState>(
          builder: (context, state) {
            if (state is AccountLoading || state is AccountInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AccountError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AccountCubit>().fetchAccounts();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (state is AccountLoaded) {
              if (state.accounts.isEmpty) {
                return const Center(child: Text('No accounts found.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<AccountCubit>().fetchAccounts();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.accounts.length,
                  itemBuilder: (context, index) {
                    Account account = state.accounts[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(Icons.account_balance, color: Colors.deepPurple),
                        ),
                        title: Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(account.bankName ?? 'No Bank Name'),
                        trailing: Text(
                          '${account.balance.toStringAsFixed(2)} ${account.currencyCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
