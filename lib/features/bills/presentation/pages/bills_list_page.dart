import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/bill_cubit.dart';
import '../../cubit/bill_state.dart';
import '../../models/bill.dart';

import '../../../../core/widgets/common_app_bar.dart';

class BillsListPage extends StatelessWidget {
  const BillsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BillCubit()..fetchBills(),
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Bills'),
        body: BlocBuilder<BillCubit, BillState>(
          builder: (context, state) {
            if (state is BillLoading || state is BillInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BillError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.deepPurple, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<BillCubit>().fetchBills();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (state is BillLoaded) {
              if (state.bills.isEmpty) {
                return const Center(child: Text('No bills found.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<BillCubit>().fetchBills();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.bills.length,
                  itemBuilder: (context, index) {
                    Bill bill = state.bills[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(
                          bill.documentNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vendor: ${bill.contactName}'),
                            Text('Issued: ${bill.issuedAt}'),
                            Text(
                              'Status: ${bill.status.toUpperCase()}',
                              style: TextStyle(
                                color: bill.status == 'paid' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${bill.amount.toStringAsFixed(2)}\n${bill.currencyCode}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                        isThreeLine: true,
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
