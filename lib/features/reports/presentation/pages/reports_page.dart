import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/report_cubit.dart';
import '../../cubit/report_state.dart';
import '../../models/report_summary.dart';

import '../../../../core/widgets/common_app_bar.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportCubit()..fetchReports(),
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Financial Reports'),
        body: BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading || state is ReportInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReportError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.deepPurple, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<ReportCubit>().fetchReports();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (state is ReportLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<ReportCubit>().fetchReports();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNetProfitCard(state.summary),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard('Total Income', state.summary.totalIncome, state.summary.currencyCode, Colors.green, Icons.arrow_downward)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMetricCard('Total Expenses', state.summary.totalExpenses, state.summary.currencyCode, Colors.red, Icons.arrow_upward)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildVisualBar(state.summary),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      ...state.recentTransactions.take(5).map((tx) {
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.type == 'income' ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                tx.type == 'income' ? Icons.add : Icons.remove,
                                color: tx.type == 'income' ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(tx.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tx.date),
                            trailing: Text(
                              '${tx.type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${tx.currencyCode}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.type == 'income' ? Colors.green : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (state.recentTransactions.isEmpty)
                         const Padding(
                           padding: EdgeInsets.all(16.0),
                           child: Center(child: Text('No transactions available for report.', style: TextStyle(color: Colors.grey))),
                         ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildNetProfitCard(ReportSummary summary) {
    Color profitColor = summary.isProfitable ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Net Profit',
            style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.netProfit >= 0 ? '' : '-'}${summary.netProfit.abs().toStringAsFixed(2)} ${summary.currencyCode}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: profitColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: profitColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  summary.isProfitable ? Icons.trending_up : Icons.trending_down,
                  color: profitColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  summary.isProfitable ? 'Profitable' : 'Loss',
                  style: TextStyle(color: profitColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, double amount, String currency, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${amount.toStringAsFixed(2)}\n$currency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualBar(ReportSummary summary) {
    double total = summary.totalIncome + summary.totalExpenses;
    if (total == 0) total = 1; // Prevent division by zero

    double incomeFlex = (summary.totalIncome / total).clamp(0.01, 1.0);
    double expenseFlex = (summary.totalExpenses / total).clamp(0.01, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Income vs Expenses Ratio',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(
                  flex: (incomeFlex * 100).toInt(),
                  child: Container(color: Colors.green),
                ),
                Expanded(
                  flex: (expenseFlex * 100).toInt(),
                  child: Container(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(incomeFlex * 100).toStringAsFixed(1)}% Income', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${(expenseFlex * 100).toStringAsFixed(1)}% Expenses', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}
