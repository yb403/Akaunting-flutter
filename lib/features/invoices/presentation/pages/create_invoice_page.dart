import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/create_invoice_cubit.dart';
import '../../cubit/create_invoice_state.dart';
import '../../../contacts/cubit/contact_cubit.dart';
import '../../../contacts/cubit/contact_state.dart';
import '../../../items/cubit/item_cubit.dart';
import '../../../items/cubit/item_state.dart';
import '../../../contacts/models/contact.dart';
import '../../../items/models/item.dart';
import '../../../../core/widgets/common_app_bar.dart';

class CreateInvoicePage extends StatelessWidget {
  const CreateInvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CreateInvoiceCubit()),
        BlocProvider(create: (context) => ContactCubit()..fetchContacts('customer')),
        BlocProvider(create: (context) => ItemCubit()..fetchItems()),
      ],
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
  final TextEditingController _issuedAtController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final TextEditingController _dueAtController = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);
  final TextEditingController _notesController = TextEditingController(text: 'Service invoice');
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _itemQuantityController = TextEditingController(text: '1');

  Contact? _selectedContact;
  Item? _selectedItem;

  @override
  void dispose() {
    _docNumberController.dispose();
    _issuedAtController.dispose();
    _dueAtController.dispose();
    _notesController.dispose();
    _itemPriceController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedContact != null && _selectedItem != null) {
      context.read<CreateInvoiceCubit>().submitInvoice(
        docNum: _docNumberController.text,
        issuedAt: _issuedAtController.text,
        dueAt: _dueAtController.text,
        contactId: _selectedContact!.id,
        contactName: _selectedContact!.name,
        contactEmail: _selectedContact!.email,
        itemId: _selectedItem!.id,
        itemName: _selectedItem!.name,
        price: double.tryParse(_itemPriceController.text) ?? _selectedItem!.salePrice,
        quantity: double.tryParse(_itemQuantityController.text) ?? 1.0,
        notes: _notesController.text,
      );
    } else if (_selectedContact == null || _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and an item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Create Invoice'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _docNumberController,
                decoration: const InputDecoration(
                  labelText: 'Document Number (Auto if empty)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _issuedAtController,
                      decoration: const InputDecoration(
                        labelText: 'Issue Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _issuedAtController.text = pickedDate.toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dueAtController,
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _dueAtController.text = pickedDate.toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<ContactCubit, ContactState>(
                builder: (context, state) {
                  if (state is ContactLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ContactLoaded) {
                    return DropdownButtonFormField<Contact>(
                      value: _selectedContact,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select Customer',
                      ),
                      items: state.contacts.map((contact) {
                        return DropdownMenuItem(
                          value: contact,
                          child: Text(contact.name),
                        );
                      }).toList(),
                      onChanged: (contact) {
                        setState(() => _selectedContact = contact);
                      },
                      validator: (value) => value == null ? 'Please select a customer' : null,
                    );
                  }
                  return const Text('Error loading customers');
                },
              ),
              const SizedBox(height: 16),
              const Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<ItemCubit, ItemState>(
                builder: (context, state) {
                  if (state is ItemLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ItemLoaded) {
                    return DropdownButtonFormField<Item>(
                      value: _selectedItem,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select Item',
                      ),
                      items: state.items.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (item) {
                        setState(() {
                          _selectedItem = item;
                          if (item != null) {
                            _itemPriceController.text = item.salePrice.toString();
                          }
                        });
                      },
                      validator: (value) => value == null ? 'Please select an item' : null,
                    );
                  }
                  return const Text('Error loading items');
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _itemQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              BlocConsumer<CreateInvoiceCubit, CreateInvoiceState>(
                listener: (context, state) {
                  if (state is CreateInvoiceSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  } else if (state is CreateInvoiceError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is CreateInvoiceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Invoice', style: TextStyle(fontSize: 16)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

