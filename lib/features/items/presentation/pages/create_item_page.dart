import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/item_cubit.dart';
import '../../cubit/item_state.dart';

class CreateItemPage extends StatefulWidget {
  const CreateItemPage({super.key});

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<ItemCubit>().addItem(
        name: _nameController.text,
        description: _descriptionController.text,
        salePrice: double.tryParse(_priceController.text) ?? 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Item'),
      ),
      body: BlocListener<ItemCubit, ItemState>(
        listener: (context, state) {
          if (state is ItemCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is ItemError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Sale Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter price' : null,
                ),
                const SizedBox(height: 24),
                BlocBuilder<ItemCubit, ItemState>(
                  builder: (context, state) {
                    if (state is ItemLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Save Item', style: TextStyle(fontSize: 16)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
