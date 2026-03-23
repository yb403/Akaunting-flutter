import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../models/item.dart';
import 'item_state.dart';

class ItemCubit extends Cubit<ItemState> {
  ItemCubit() : super(ItemInitial());

  Future<void> fetchItems() async {
    emit(ItemLoading());

    try {
      var response = await ApiClient.getRequest('/items?page=1&limit=50');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('data')) {
          List<dynamic> itemsJson = data['data'];
          List<Item> itemsList = itemsJson.map((e) => Item.fromJson(e)).toList();
          emit(ItemLoaded(itemsList));
        } else {
          emit(const ItemError('Unexpected response format from server.'));
        }
      } else {
        emit(ItemError('Failed to load items: ${response.statusCode} - ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(ItemError('An error occurred while fetching items: $e'));
    }
  }
}
