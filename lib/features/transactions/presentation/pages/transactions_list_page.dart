import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/transaction_cubit.dart';
import '../../cubit/transaction_state.dart';
import '../../models/transaction.dart';

import '../../../../core/widgets/common_app_bar.dart';

class TransactionsListPage extends StatelessWidget {
  const TransactionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionCubit()..fetchTransactions(),
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Transactions'),
        body: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading || state is TransactionInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TransactionError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.purple, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<TransactionCubit>().fetchTransactions();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (state is TransactionLoaded) {
              if (state.transactions.isEmpty) {
                return const Center(child: Text('No transactions found.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<TransactionCubit>().fetchTransactions();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.transactions.length,
                  itemBuilder: (context, index) {
                    Transaction tx = state.transactions[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.type == 'income' ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.type == 'income' ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          tx.type.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Date: ${tx.date}'),
                        trailing: Text(
                          '${tx.type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)}\n${tx.currencyCode}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: tx.type == 'income' ? Colors.green : Colors.red,
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
