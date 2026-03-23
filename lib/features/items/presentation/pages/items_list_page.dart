import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/item_cubit.dart';
import '../../cubit/item_state.dart';
import '../../models/item.dart';

class ItemsListPage extends StatelessWidget {
  const ItemsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemCubit()..fetchItems(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Items'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<ItemCubit, ItemState>(
          builder: (context, state) {
            if (state is ItemLoading || state is ItemInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ItemError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.indigo, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ItemCubit>().fetchItems();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (state is ItemLoaded) {
              if (state.items.isEmpty) {
                return const Center(child: Text('No items found.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<ItemCubit>().fetchItems();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    Item item = state.items[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: const Icon(Icons.inventory_2, color: Colors.indigo),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          '${item.salePrice.toStringAsFixed(2)}\nUSD',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
