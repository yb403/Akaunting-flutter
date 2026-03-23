import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../models/account.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(AccountInitial());

  Future<void> fetchAccounts() async {
    emit(AccountLoading());

    try {
      var response = await ApiClient.getRequest('/accounts?page=1&limit=50');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> accountsJson = data['data'];
          List<Account> accountsList = accountsJson.map((e) => Account.fromJson(e)).toList();
          emit(AccountLoaded(accountsList));
        } else {
          emit(const AccountError('Unexpected response format from server.'));
        }
      } else {
        emit(AccountError('Failed to load accounts: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(AccountError('An error occurred while fetching accounts: $e'));
    }
  }
}
