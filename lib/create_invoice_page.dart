import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for dynamic input
  final TextEditingController _docNumberController = TextEditingController();
  final TextEditingController _issuedAtController = TextEditingController(text: '2022-04-23');
  final TextEditingController _dueAtController = TextEditingController(text: '2022-05-22');
  final TextEditingController _notesController = TextEditingController(text: 'This is note for invoice');
  final TextEditingController _contactNameController = TextEditingController(text: 'Name');
  final TextEditingController _contactEmailController = TextEditingController(text: 'mail@mail.com');
  final TextEditingController _itemNameController = TextEditingController(text: 'Service');
  final TextEditingController _itemPriceController = TextEditingController(text: '1');
  final TextEditingController _itemQuantityController = TextEditingController(text: '2');
  
  bool _isLoading = false;
  String _response = '';

  Future<void> _createInvoice() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String email = prefs.getString('email') ?? '';
      String password = prefs.getString('password') ?? '';
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$email:$password'))}';

      var headers = {
        'X-Company': 'akaunting_company_id',
        'Authorization': basicAuth
      };
      
      // Calculate total correctly
      double price = double.tryParse(_itemPriceController.text) ?? 0.0;
      double quantity = double.tryParse(_itemQuantityController.text) ?? 0.0;
      double total = price * quantity;

      // Ensure doc number is unique if empty
      String docNum = _docNumberController.text.isNotEmpty 
          ? _docNumberController.text 
          : 'INV-${DateTime.now().millisecondsSinceEpoch}';

      String url = 'http://192.168.1.116/akaunting/api/documents'
          '?type=invoice'
          '&category_id=3'
          '&document_number=${Uri.encodeComponent(docNum)}'
          '&status=draft'
          '&issued_at=${Uri.encodeComponent(_issuedAtController.text)}'
          '&due_at=${Uri.encodeComponent(_dueAtController.text)}'
          '&account_id=1'
          '&currency_code=USD'
          '&currency_rate=1'
          '&notes=${Uri.encodeComponent(_notesController.text)}'
          '&contact_id=2'
          '&contact_name=${Uri.encodeComponent(_contactNameController.text)}'
          '&contact_email=${Uri.encodeComponent(_contactEmailController.text)}'
          '&contact_address=${Uri.encodeComponent('Client address')}'
          '&items[0][item_id]=1'
          '&items[0][name]=${Uri.encodeComponent(_itemNameController.text)}'
          '&items[0][quantity]=${quantity.toInt()}'
          '&items[0][price]=${price.toInt()}'
          '&items[0][total]=${total.toInt()}'
          '&items[0][discount]=0'
          '&items[0][description]=${Uri.encodeComponent('This is custom item description')}'
          '&items[0][tax_ids][0]=1'
          '&items[0][tax_ids][1]=1'
          '&amount=0'
          '&search=type:invoice';
      
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll(headers);

      print('--- REQUEST ---');
      print('URL: $url');
      print('Method: POST');
      print('Headers: $headers');

      http.StreamedResponse response = await request.send();

      String resultText = await response.stream.bytesToString();

      print('--- RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: $resultText');

      setState(() {
        _response = 'Status: ${response.statusCode}\n\nResult:\n$resultText';
      });
    } catch (e) {
      print(e);
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createInvoice,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Create Invoice'),
                      ),
                      const SizedBox(height: 16),
                      if (_response.isNotEmpty) ...[
                        const Text(
                          'Response:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_response),
                      ],
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
