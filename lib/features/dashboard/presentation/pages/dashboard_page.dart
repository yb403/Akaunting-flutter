import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../invoices/cubit/invoice_cubit.dart';
import '../../../invoices/cubit/invoice_state.dart';
import '../../../transactions/cubit/transaction_cubit.dart';
import '../../../transactions/cubit/transaction_state.dart';
import '../../../bills/cubit/bill_cubit.dart';
import '../../../bills/cubit/bill_state.dart';
import '../../../invoices/presentation/pages/invoices_list_page.dart';
import '../../../bills/presentation/pages/bills_list_page.dart';
import '../../../contacts/presentation/pages/contacts_page.dart';
import '../../../items/presentation/pages/items_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => InvoiceCubit()..fetchInvoices()),
        BlocProvider(create: (context) => TransactionCubit()..fetchTransactions()),
        BlocProvider(create: (context) => BillCubit()..fetchBills()),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildRecentSectionTitle('Recent Invoices', () {
                      // Navigate to Invoices tab
                    }),
                    const SizedBox(height: 12),
                    _buildRecentInvoices(),
                    const SizedBox(height: 24),
                    _buildRecentSectionTitle('Recent Transactions', () {
                      // Navigate to Transactions (via More or specific page)
                    }),
                    const SizedBox(height: 12),
                    _buildRecentTransactions(),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple, Colors.indigo],
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Akaunting Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        double income = 0;
        double expenses = 0;
        if (state is TransactionLoaded) {
          for (var tx in state.transactions) {
            if (tx.type == 'income') {
              income += tx.amount;
            } else {
              expenses += tx.amount;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(income - expenses).toStringAsFixed(2)} USD',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildSummaryItem(
                    'Income',
                    income.toStringAsFixed(2),
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                  const SizedBox(width: 20),
                  _buildSummaryItem(
                    'Expenses',
                    expenses.toStringAsFixed(2),
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildActionIcon(context, Icons.receipt_long, 'Invoices', Colors.blue, const InvoicesListPage()),
            _buildActionIcon(context, Icons.receipt, 'Bills', Colors.red, const BillsListPage()),
            _buildActionIcon(context, Icons.person_outline, 'Contacts', Colors.teal, const ContactsPage()),
            _buildActionIcon(context, Icons.inventory_2_outlined, 'Items', Colors.orange, const ItemsListPage()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSectionTitle(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices() {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        if (state is InvoiceLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is InvoiceLoaded) {
          final invoices = state.invoices.take(3).toList();
          if (invoices.isEmpty) {
            return const Center(child: Text('No recent invoices'));
          }
          return Column(
            children: invoices.map((invoice) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.description, color: Colors.blue, size: 20),
                  ),
                  title: Text(
                    invoice.documentNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(invoice.contactName),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${invoice.amount.toStringAsFixed(2)} ${invoice.currencyCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text(
                        invoice.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: invoice.status == 'paid' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildRecentTransactions() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TransactionLoaded) {
          final transactions = state.transactions.take(3).toList();
          if (transactions.isEmpty) {
            return const Center(child: Text('No recent transactions'));
          }
          return Column(
            children: transactions.map((tx) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.type == 'income' ? Colors.green[50] : Colors.red[50],
                    child: Icon(
                      tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.type == 'income' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.type.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tx.date),
                  trailing: Text(
                    '${tx.type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${tx.currencyCode}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.type == 'income' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }
        return const SizedBox();
      },
    );
  }
}
