import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import 'create_invoice_state.dart';

class CreateInvoiceCubit extends Cubit<CreateInvoiceState> {
  CreateInvoiceCubit() : super(CreateInvoiceInitial());

  Future<void> submitInvoice({
    required String docNum,
    required String issuedAt,
    required String dueAt,
    required String contactName,
    required String contactEmail,
    required String itemName,
    required double price,
    required double quantity,
    required String notes,
  }) async {
    emit(CreateInvoiceLoading());

    try {
      double total = price * quantity;

      String finalDocNum = docNum.isNotEmpty 
          ? docNum 
          : 'INV-${DateTime.now().millisecondsSinceEpoch}';

      String fullUrl = '${ApiClient.baseUrl}/documents'
          '?type=invoice'
          '&category_id=3'
          '&document_number=${Uri.encodeComponent(finalDocNum)}'
          '&status=draft'
          '&issued_at=${Uri.encodeComponent(issuedAt)}'
          '&due_at=${Uri.encodeComponent(dueAt)}'
          '&account_id=1'
          '&currency_code=USD'
          '&currency_rate=1'
          '&notes=${Uri.encodeComponent(notes)}'
          '&contact_id=2'
          '&contact_name=${Uri.encodeComponent(contactName)}'
          '&contact_email=${Uri.encodeComponent(contactEmail)}'
          '&contact_address=${Uri.encodeComponent('Client address')}'
          '&items[0][item_id]=1'
          '&items[0][name]=${Uri.encodeComponent(itemName)}'
          '&items[0][quantity]=${quantity.toInt()}'
          '&items[0][price]=${price.toInt()}'
          '&items[0][total]=${total.toInt()}'
          '&items[0][discount]=0'
          '&items[0][description]=${Uri.encodeComponent('This is custom item description')}'
          '&items[0][tax_ids][0]=1'
          '&items[0][tax_ids][1]=1'
          '&amount=0'
          '&search=type:invoice';

      var response = await ApiClient.multipartPostRequest(fullUrl);
      String resultText = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        emit(CreateInvoiceSuccess('Invoice Created Successfully!\nDetails: $resultText'));
      } else {
        emit(CreateInvoiceError('Failed to create invoice: HTTP ${response.statusCode}\n$resultText'));
      }
    } catch (e) {
      emit(CreateInvoiceError('An error occurred: $e'));
    }
  }

  void reset() {
    emit(CreateInvoiceInitial());
  }
}
