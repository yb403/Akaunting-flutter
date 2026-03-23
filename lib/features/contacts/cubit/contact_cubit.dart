import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../models/contact.dart';
import 'contact_state.dart';

class ContactCubit extends Cubit<ContactState> {
  ContactCubit() : super(ContactInitial());

  // Can fetch either 'customer' or 'vendor'
  Future<void> fetchContacts(String type) async {
    emit(ContactLoading());

    try {
      var response = await ApiClient.getRequest('/contacts?search=type:$type&page=1&limit=50');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> contactsJson = data['data'];
          List<Contact> contactsList = contactsJson.map((e) => Contact.fromJson(e)).toList();
          emit(ContactLoaded(contactsList));
        } else {
          emit(const ContactError('Unexpected response format from server.'));
        }
      } else {
        emit(ContactError('Failed to load contacts: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(ContactError('An error occurred while fetching contacts: $e'));
    }
  }
}
