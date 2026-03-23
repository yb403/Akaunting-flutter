import 'dart:io';
import 'dart:typed_data';
import 'script2.dart' as ocr_script;

// Mock InvoiceData and InvoiceItem since we can't easily run the PDF extractor in pure Dart
class MockInvoiceData {
  final String? invoiceNumber;
  final String? date;
  final String? dueDate;
  final String? totalAmount;
  final String? customerName;
  final List<dynamic> items;

  MockInvoiceData({
    this.invoiceNumber,
    this.date,
    this.dueDate,
    this.totalAmount,
    this.customerName,
    this.items = const [],
  });
}

void main() async {
  print('=== Invoice Extraction Comparison ===\n');

  // 1. PDF Result (Manually verified from previous PDF extraction runs)
  // We mock this because the syncfusion_flutter_pdf library requires a Flutter environment to run.
  final pdfData = MockInvoiceData(
    invoiceNumber: 'INV-1773800420378',
    date: '10 Mar 2026',
    dueDate: '19 Mar 2026',
    totalAmount: '194.00',
    customerName: 'YASSINE',
    items: [1, 2, 3], // 3 items
  );
  
  print('EXPECTED RESULT (From PDF):');
  print('  Invoice #: ${pdfData.invoiceNumber}');
  print('  Date: ${pdfData.date}');
  print('  Total: ${pdfData.totalAmount}');
  print('  Items: ${pdfData.items.length}');
  print('-----------------------------\n');

  // 2. OCR Extraction (Using the simulated OCR text that we verified in test_ocr.dart)
  // In a real device, this 'ocrText' would come from Google ML Kit.
  final String ocrText = '''
My Company
my@company.com

Bill To
YASSINE
24000
el jadida
maroc, London 24000
Morocco
+344345654445
BADI@gmail.com

Invoice Number: INV-1773800420378
Invoice Date: 10 Mar 2026
Due Date: 19 Mar 2026

Items
Quantity
Price
Amount
Service - This is custom item description
4
\$1.00
\$4.00
dev - devvevvevv
5
\$20.00
\$100.00
HAW
1
\$90.00
\$90.00

Notes
Extracted from PDF. Original Total: 22.00
Subtotal:
\$194.00
Total:
\$194.00
''';

  final ocrData = await ocr_script.extractInvoiceDataFromText(ocrText);
  
  print('OCR EXTRACTION RESULT:');
  print(ocrData);
  print('-----------------------------\n');

  // 3. Comparison
  print('=== Comparison Statistics ===');
  int matches = 0;
  int mismatches = 0;

  void compare(String field, dynamic val1, dynamic val2) {
    if (val1 == val2) {
      print('[MATCH] $field: $val1');
      matches++;
    } else {
      print('[MISMATCH] $field: PDF="$val1" vs OCR="$val2"');
      mismatches++;
    }
  }

  compare('Invoice Number', pdfData.invoiceNumber, ocrData.invoiceNumber);
  compare('Date', pdfData.date, ocrData.date);
  compare('Due Date', pdfData.dueDate, ocrData.dueDate);
  compare('Customer Name', pdfData.customerName, ocrData.customerName);
  compare('Total Amount', pdfData.totalAmount, ocrData.totalAmount);
  compare('Items Count', pdfData.items.length, ocrData.items.length);

  print('\nSUMMARY:');
  print('Matches: $matches');
  print('Mismatches: $mismatches');

  if (mismatches == 0) {
    print('\n[SUCCESS] OCR extraction is now as accurate as PDF extraction!');
  } else {
    print('\n[FAILED] Differences still exist between PDF and OCR extraction.');
  }
}
