import 'script2.dart';

void main() async {
  // Test 1: Simulated OCR text from invoice.png
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

  print('--- OCR Standalone Test ---');
  final data = await extractInvoiceDataFromText(ocrText);
  print(data);
  
  print('\n--- Verification ---');
  bool ok = true;
  if (data.invoiceNumber != 'INV-1773800420378') {
      print('MISSING/WRONG Invoice Number: ${data.invoiceNumber}');
      ok = false;
  }
  if (data.date != '10 Mar 2026') {
      print('MISSING/WRONG Date: ${data.date}');
      ok = false;
  }
  if (data.totalAmount != '194.00') {
      print('MISSING/WRONG Total Amount: ${data.totalAmount}');
      ok = false;
  }
  if (data.items.length != 3) {
      print('INCORRECT Items count: ${data.items.length}');
      ok = false;
  } else {
      print('Items extracted successfully: ${data.items.length}');
  }

  if (ok) {
      print('\n[SUCCESS] OCR Parsing matches expectations!');
  } else {
      print('\n[FAILED] OCR Parsing needs further tuning.');
  }
}
