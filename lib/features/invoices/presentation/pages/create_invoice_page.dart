import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/create_invoice_cubit.dart';
import '../../cubit/create_invoice_state.dart';

class CreateInvoicePage extends StatelessWidget {
  const CreateInvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateInvoiceCubit(),
      child: const _CreateInvoiceForm(),
    );
  }
}

class _CreateInvoiceForm extends StatefulWidget {
  const _CreateInvoiceForm();

  @override
  State<_CreateInvoiceForm> createState() => _CreateInvoiceFormState();
}

class _CreateInvoiceFormState extends State<_CreateInvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _docNumberController = TextEditingController();
  final TextEditingController _issuedAtController = TextEditingController(text: '2022-04-23');
  final TextEditingController _dueAtController = TextEditingController(text: '2022-05-22');
  final TextEditingController _notesController = TextEditingController(text: 'This is note for invoice');
  final TextEditingController _contactNameController = TextEditingController(text: 'Name');
  final TextEditingController _contactEmailController = TextEditingController(text: 'mail@mail.com');
  final TextEditingController _itemNameController = TextEditingController(text: 'Service');
  final TextEditingController _itemPriceController = TextEditingController(text: '1');
  final TextEditingController _itemQuantityController = TextEditingController(text: '2');

  @override
  void dispose() {
    _docNumberController.dispose();
    _issuedAtController.dispose();
    _dueAtController.dispose();
    _notesController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CreateInvoiceCubit>().submitInvoice(
        docNum: _docNumberController.text,
        issuedAt: _issuedAtController.text,
        dueAt: _dueAtController.text,
        contactName: _contactNameController.text,
        contactEmail: _contactEmailController.text,
        itemName: _itemNameController.text,
        price: double.tryParse(_itemPriceController.text) ?? 0.0,
        quantity: double.tryParse(_itemQuantityController.text) ?? 0.0,
        notes: _notesController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _docNumberController,
                        decoration: const InputDecoration(labelText: 'Document Number (Leave blank for auto)'),
                      ),
                      TextFormField(
                        controller: _issuedAtController,
                        decoration: const InputDecoration(labelText: 'Issue Date (YYYY-MM-DD)'),
                      ),
                      TextFormField(
                        controller: _dueAtController,
                        decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                      ),
                      TextFormField(
                        controller: _contactNameController,
                        decoration: const InputDecoration(labelText: 'Client Name'),
                      ),
                      TextFormField(
                        controller: _contactEmailController,
                        decoration: const InputDecoration(labelText: 'Client Email'),
                      ),
                      TextFormField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(labelText: 'Item Name'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _itemPriceController,
                              decoration: const InputDecoration(labelText: 'Item Price'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _itemQuantityController,
                              decoration: const InputDecoration(labelText: 'Item Quantity'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<CreateInvoiceCubit, CreateInvoiceState>(
                        builder: (context, state) {
                          if (state is CreateInvoiceLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Create Invoice'),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<CreateInvoiceCubit, CreateInvoiceState>(
                        builder: (context, state) {
                          if (state is CreateInvoiceSuccess) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.green.shade100,
                              child: Text(state.message, style: const TextStyle(color: Colors.green)),
                            );
                          } else if (state is CreateInvoiceError) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.red.shade100,
                              child: Text(state.message, style: const TextStyle(color: Colors.red)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
