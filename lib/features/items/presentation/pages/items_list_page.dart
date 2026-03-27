import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/item_cubit.dart';
import '../../cubit/item_state.dart';
import '../../models/item.dart';
import 'create_item_page.dart';

import '../../../../core/widgets/common_app_bar.dart';

class ItemsListPage extends StatelessWidget {
  const ItemsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemCubit()..fetchItems(),
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Items'),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<ItemCubit>(),
                    child: const CreateItemPage(),
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
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
                      const Icon(Icons.error_outline, color: Colors.deepPurple, size: 60),
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
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
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
