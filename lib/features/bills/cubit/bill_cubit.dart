import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../models/bill.dart';
import 'bill_state.dart';

class BillCubit extends Cubit<BillState> {
  BillCubit() : super(BillInitial());

  Future<void> fetchBills() async {
    emit(BillLoading());

    try {
      var response = await ApiClient.getRequest('/documents?search=type:bill&page=1&limit=50');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> billsJson = data['data'];
          List<Bill> billsList = billsJson.map((e) => Bill.fromJson(e)).toList();
          emit(BillLoaded(billsList));
        } else {
          emit(const BillError('Unexpected response format from server.'));
        }
      } else {
        emit(BillError('Failed to load bills: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(BillError('An error occurred while fetching bills: $e'));
    }
  }
}
