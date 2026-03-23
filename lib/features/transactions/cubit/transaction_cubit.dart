import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../models/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit() : super(TransactionInitial());

  Future<void> fetchTransactions() async {
    emit(TransactionLoading());

    try {
      var response = await ApiClient.getRequest('/transactions?page=1&limit=50');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> txsJson = data['data'];
          List<Transaction> txsList = txsJson.map((e) => Transaction.fromJson(e)).toList();
          emit(TransactionLoaded(txsList));
        } else {
          emit(const TransactionError('Unexpected response format from server.'));
        }
      } else {
        emit(TransactionError('Failed to load transactions: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(TransactionError('An error occurred while fetching transactions: $e'));
    }
  }
}
