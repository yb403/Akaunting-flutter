import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../models/invoice.dart';
import 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit() : super(InvoiceInitial());

  Future<void> fetchInvoices() async {
    emit(InvoiceLoading());

    try {
      var response = await ApiClient.getRequest('/documents?search=type:invoice&page=1&limit=50');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> invoicesJson = data['data'];
          List<Invoice> invoicesList = invoicesJson.map((e) => Invoice.fromJson(e)).toList();
          emit(InvoiceLoaded(invoicesList));
        } else {
          emit(const InvoiceError('Unexpected response format from server.'));
        }
      } else {
        emit(InvoiceError('Failed to load invoices: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(InvoiceError('An error occurred while fetching invoices: $e'));
    }
  }
}
