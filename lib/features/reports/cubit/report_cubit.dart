import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../transactions/models/transaction.dart';
import '../models/report_summary.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit() : super(ReportInitial());

  Future<void> fetchReports() async {
    emit(ReportLoading());

    try {
      // Fetch both income and expense transactions. 
      // For simplicity in this demo, pulling the latest 100 transactions and aggregating them locally.
      var response = await ApiClient.getRequest('/transactions?page=1&limit=100');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> txsJson = data['data'];
          List<Transaction> txsList = txsJson.map((e) => Transaction.fromJson(e)).toList();

          double income = 0;
          double expenses = 0;
          String currency = 'USD'; // Default fallback

          for (var tx in txsList) {
            if (tx.type == 'income') {
              income += tx.amount;
            } else if (tx.type == 'expense') {
              expenses += tx.amount;
            }
            currency = tx.currencyCode;
          }

          final summary = ReportSummary(
            totalIncome: income,
            totalExpenses: expenses,
            netProfit: income - expenses,
            currencyCode: currency,
          );

          emit(ReportLoaded(summary, txsList));
        } else {
          emit(const ReportError('Unexpected response format from server.'));
        }
      } else {
        emit(ReportError('Failed to load report data: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(ReportError('An error occurred while fetching reports: $e'));
    }
  }
}
