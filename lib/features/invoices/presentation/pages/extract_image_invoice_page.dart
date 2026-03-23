import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../script2.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExtractImageInvoicePage extends StatefulWidget {
  const ExtractImageInvoicePage({super.key});

  @override
  State<ExtractImageInvoicePage> createState() => _ExtractImageInvoicePageState();
}

class _ExtractImageInvoicePageState extends State<ExtractImageInvoicePage> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to process an Image';
  String? _selectedFileName;
  File? _selectedImageFile;
  InvoiceData? _extractedData;
  String? _apiResponse;

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final date = DateFormat('dd MMM yyyy').parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      print('Date parsing failed for "$dateStr": $e');
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  Future<void> _pickAndProcessImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false, // We need the path for ML Kit on some platforms
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedImageFile = File(path);
          _isLoading = true;
          _statusMessage = 'Performing OCR on $_selectedFileName...';
          _apiResponse = null;
          _extractedData = null;
        });

        await _processImage(path);
      } else {
        setState(() {
          _statusMessage = 'No image selected';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Picker Error: $e';
      });
    }
  }

  Future<void> _processSampleImage() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Extracting data from invoice.png asset...';
      _apiResponse = null;
      _extractedData = null;
      _selectedFileName = 'invoice.png';
    });

    try {
      // For assets, we might need to write to a temp file because ML Kit needs a path or bytes
      final ByteData data = await rootBundle.load('lib/invoice.png');
      final bytes = data.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_invoice.png');
      await tempFile.writeAsBytes(bytes);
      
      await _processImage(tempFile.path);
    } catch (e) {
      setState(() {
        _statusMessage = 'Asset Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage(String path) async {
    try {
      // 1. OCR Extraction
      final InputImage inputImage = InputImage.fromFilePath(path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      print('RAW OCR TEXT START:');
      print(recognizedText.text);
      print('RAW OCR TEXT END');

      // 2. Parse from recognized text
      final data = await extractInvoiceDataFromText(recognizedText.text);
      
      setState(() {
        _extractedData = data;
        _statusMessage = 'OCR Completed! Sending to API...';
      });

      // 3. Prepare API Request (Shared Logic)
      await _sendToAkaunting(data);

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

  Future<void> _sendToAkaunting(InvoiceData data) async {
    // Shared API logic with PDF page
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
        '&document_number=${Uri.encodeComponent(data.invoiceNumber ?? "IMG-${DateTime.now().millisecondsSinceEpoch}")}'
        '&status=draft'
        '&issued_at=${Uri.encodeComponent(_formatDate(data.date))}'
        '&due_at=${Uri.encodeComponent(_formatDate(data.dueDate))}'
        '&account_id=1'
        '&currency_code=USD'
        '&currency_rate=1'
        '&notes=${Uri.encodeComponent('Extracted via OCR from Image. Original Total: ${data.totalAmount}')}'
        '&contact_id=2'
        '&contact_name=${Uri.encodeComponent(data.customerName ?? "Unknown")}'
        '&contact_email=${Uri.encodeComponent("mail@mail.com")}'
        '&contact_address=${Uri.encodeComponent("Extracted Address")}'
        '&search=type:invoice';

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

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    String resultText = await response.stream.bytesToString();

    setState(() {
      _apiResponse = 'Status: ${response.statusCode}\nBody: $resultText';
      _statusMessage = response.statusCode == 200 || response.statusCode == 201 
          ? 'Invoice created successfully from Image!' 
          : 'Failing to create invoice (Status: ${response.statusCode})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract from Image (OCR)'),
        backgroundColor: Colors.orangeAccent,
      ),
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
                    const Icon(Icons.image, size: 64, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName != null 
                        ? 'Selected: $_selectedFileName' 
                        : 'No image selected', 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickAndProcessImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick Image & Create Invoice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _processSampleImage,
                          icon: const Icon(Icons.history),
                          label: const Text('Use Sample Asset (invoice.png)'),
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
                color: _statusMessage.contains('Error') ? Colors.red : Colors.orange[800],
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
                  style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
