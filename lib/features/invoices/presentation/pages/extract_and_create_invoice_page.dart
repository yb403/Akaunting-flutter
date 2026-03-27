import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../script.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/common_app_bar.dart';

class ExtractAndCreateInvoicePage extends StatefulWidget {
  const ExtractAndCreateInvoicePage({super.key});

  @override
  State<ExtractAndCreateInvoicePage> createState() => _ExtractAndCreateInvoicePageState();
}

class _ExtractAndCreateInvoicePageState extends State<ExtractAndCreateInvoicePage> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to process a PDF';
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  InvoiceData? _extractedData;
  String? _apiResponse;

  // Manual Month Mapping as fallback or for simplicity if intl is picky
  String _formatDate(String? dateStr) {
    if (dateStr == null) return DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      // Try to parse "10 Mar 2026"
      // DateFormat pattern 'dd MMM yyyy'
      final date = DateFormat('dd MMM yyyy').parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      print('Date parsing failed for "$dateStr": $e');
      // If it fails, try simple regex or return today
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  Future<void> _pickAndProcessInvoice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFileBytes = result.files.single.bytes;
          _isLoading = true;
          _statusMessage = 'Extracting data from $_selectedFileName...';
          _apiResponse = null;
          _extractedData = null;
        });

        // Use the bytes from the picker
        await _processInvoiceData(_selectedFileBytes!);
      } else {
        setState(() {
          _statusMessage = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Picker Error: $e';
      });
    }
  }

  Future<void> _processAssetInvoice() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Extracting data from invoice.pdf asset...';
      _apiResponse = null;
      _extractedData = null;
      _selectedFileName = 'invoice.pdf';
    });

    try {
      final ByteData assetData = await rootBundle.load('assets/demo_invoice.pdf');
      final Uint8List bytes = assetData.buffer.asUint8List();
      await _processInvoiceData(bytes);
    } catch (e) {
      setState(() {
        _statusMessage = 'Asset Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processInvoiceData(Uint8List bytes) async {
    try {
      // 1. Extract Data directly from bytes
      final data = await extractInvoiceDataFromBytes(bytes);
      setState(() {
        _extractedData = data;
        _statusMessage = 'Data extracted successfully! Sending to API...';
      });

      // 3. Prepare API Request
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String email = prefs.getString('email') ?? '';
      String password = prefs.getString('password') ?? '';
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$email:$password'))}';

      var headers = {
        'X-Company': 'akaunting_company_id',
        'Authorization': basicAuth
      };

      String url = 'http://192.168.1.116/akaunting/api/documents'
          '?type=invoice'
          '&category_id=3'
          '&document_number=${Uri.encodeComponent(data.invoiceNumber ?? "INV-${DateTime.now().millisecondsSinceEpoch}")}'
          '&status=draft'
          '&issued_at=${Uri.encodeComponent(_formatDate(data.date))}'
          '&due_at=${Uri.encodeComponent(_formatDate(data.dueDate))}'
          '&account_id=1'
          '&currency_code=USD'
          '&currency_rate=1'
          '&notes=${Uri.encodeComponent('Extracted from PDF. Original Total: ${data.totalAmount}')}'
          '&contact_id=2'
          '&contact_name=${Uri.encodeComponent(data.customerName ?? "Unknown")}'
          '&contact_email=${Uri.encodeComponent("mail@mail.com")}'
          '&contact_address=${Uri.encodeComponent("Extracted Address")}'
          '&search=type:invoice';

      // Add Items dynamically
      for (int i = 0; i < data.items.length; i++) {
        final item = data.items[i];
        final qty = double.tryParse(item.quantity) ?? 1.0;
        final price = double.tryParse(item.price) ?? 0.0;
        final total = double.tryParse(item.amount) ?? (qty * price);

        url += '&items[$i][item_id]=1'
            '&items[$i][name]=${Uri.encodeComponent(item.description)}'
            '&items[$i][quantity]=${qty.toInt()}'
            '&items[$i][price]=${price.toInt()}'
            '&items[$i][total]=${total.toInt()}'
            '&items[$i][discount]=0'
            '&items[$i][description]=${Uri.encodeComponent(item.description)}'
            '&items[$i][tax_ids][0]=1';
      }

      url += '&amount=0';

      // 4. Send Request
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      print('--- AUTOMATED REQUEST ---');
      print('URL: $url');

      http.StreamedResponse response = await request.send();
      String resultText = await response.stream.bytesToString();

      setState(() {
        _apiResponse = 'Status: ${response.statusCode}\nBody: $resultText';
        _statusMessage = response.statusCode == 200 || response.statusCode == 201 
            ? 'Invoice created successfully!' 
            : 'Failing to create invoice (Status: ${response.statusCode})';
      });

    } catch (e) {
      print('Error: $e');
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
     title: 'Extract & Create Invoice'),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName != null 
                        ? 'Selected: $_selectedFileName' 
                        : 'No file selected', 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickAndProcessInvoice,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Pick PDF & Create Invoice'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _processAssetInvoice,
                          icon: const Icon(Icons.history),
                          label: const Text('Use Sample Asset (invoice.pdf)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Status: $_statusMessage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _statusMessage.contains('Error') ? Colors.red : Colors.deepPurple[800],
              ),
            ),
            if (_extractedData != null) ...[
              const SizedBox(height: 24),
              const Text('Extracted Preview:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_extractedData.toString()),
              ),
            ],
            if (_apiResponse != null) ...[
              const SizedBox(height: 24),
              const Text('API Response:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _apiResponse!,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
