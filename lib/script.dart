import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class InvoiceItem {
  final String description;
  final String quantity;
  final String price;
  final String amount;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.price,
    required this.amount,
  });

  @override
  String toString() => '  - $description (Qty: $quantity, Price: $price, Total: $amount)';
}

class InvoiceData {
  final String? invoiceNumber;
  final String? date;
  final String? dueDate;
  final String? totalAmount;
  final String? customerName;
  final List<InvoiceItem> items;
  final List<String> extractedLines;

  InvoiceData({
    this.invoiceNumber,
    this.date,
    this.dueDate,
    this.totalAmount,
    this.customerName,
    this.items = const [],
    required this.extractedLines,
  });

  @override
  String toString() {
    return 'InvoiceData(\n'
        '  Invoice #: $invoiceNumber\n'
        '  Date: $date\n'
        '  Due Date: $dueDate\n'
        '  Total Amount: $totalAmount\n'
        '  Customer: $customerName\n'
        '  Items:\n${items.isNotEmpty ? items.join('\n') : '  (None found)'}\n'
        ')';
  }
}

Future<InvoiceData> extractInvoiceData(String filePath) async {
  final File file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('File not found: $filePath');
  }

  final List<int> bytes = await file.readAsBytes();
  return extractInvoiceDataFromBytes(Uint8List.fromList(bytes));
}

Future<InvoiceData> extractInvoiceDataFromBytes(Uint8List bytes) async {
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  final PdfTextExtractor extractor = PdfTextExtractor(document);
  String text = extractor.extractText();
  document.dispose();

  // FIX: Remove null bytes which appear in some PDF extractions
  text = text.replaceAll('\u0000', '');

  final List<String> lines = text.split('\n').map((l) => l.trim()).toList();
  return _parseInvoiceFromLines(lines);
}

Future<InvoiceData> extractInvoiceDataFromText(String text) async {
  final List<String> lines = text.split('\n').map((l) => l.trim()).toList();
  return _parseInvoiceFromLines(lines);
}

InvoiceData _parseInvoiceFromLines(List<String> lines) {
  String? invoiceNumber;
  String? date;
  String? dueDate;
  String? totalAmount;
  String? customerName;
  List<InvoiceItem> items = [];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineLower = line.toLowerCase();
    
    // Helper to get value from current or next line
    String? getValue(int index) {
        final currentLine = lines[index];
        if (currentLine.contains(':')) {
            final parts = currentLine.split(':');
            final val = parts.length > 1 ? parts.last.trim() : '';
            if (val.isNotEmpty) return val;
        }
        if (index + 1 < lines.length) {
            return lines[index + 1];
        }
        return null;
    }

    if (lineLower.contains('invoice number')) {
        invoiceNumber = getValue(i);
    } else if (lineLower.contains('invoice date')) {
        date = getValue(i);
    } else if (lineLower.contains('due date')) {
        dueDate = getValue(i);
    } else if (lineLower == 'bill to' && i + 1 < lines.length) {
        customerName = lines[i + 1];
    } else if (lineLower.contains('total:')) {
        if (i > 0 && lines[i-1].contains('\$')) {
            totalAmount = lines[i-1];
        } else if (i + 1 < lines.length && lines[i+1].contains('\$')) {
            totalAmount = lines[i+1];
        } else if (lineLower.contains('\$')) {
            // Check if price is in same line as "Total:"
            final match = RegExp(r'\$([\d,.]+)').firstMatch(line);
            if (match != null) totalAmount = match.group(0);
        }
    }
  }

  // Parse Items
  int itemsStart = lines.indexWhere((l) => l.toLowerCase() == 'items');
  if (itemsStart != -1) {
      int pointer = itemsStart + 1; // Start right after "Items" header
      // OCR might not have the exact 4-line gap, so let's be more flexible
      while (pointer < lines.length) {
          final current = lines[pointer];
          final currentLower = current.toLowerCase();
          if (currentLower.startsWith('notes') || 
              currentLower.startsWith('subtotal') ||
              currentLower.contains('total:')) break;

          // Look for a line that might be a quantity or price
          // Typically: Description, Qty, Price, Amount
          if (pointer + 3 < lines.length) {
              // Simple check for quantity-like string (number)
              String qStr = lines[pointer + 1].trim();
              String pStr = lines[pointer + 2].trim().replaceAll('\$', '');
              String aStr = lines[pointer + 3].trim().replaceAll('\$', '');

              if (RegExp(r'^\d+$').hasMatch(qStr) && 
                  (RegExp(r'^\d+').hasMatch(pStr) || pStr.contains('.'))) {
                  items.add(InvoiceItem(
                      description: current,
                      quantity: qStr,
                      price: pStr,
                      amount: aStr,
                  ));
                  pointer += 4;
                  continue;
              }
          }
          pointer++;
      }
  }

  return InvoiceData(
    invoiceNumber: invoiceNumber,
    date: date,
    dueDate: dueDate,
    totalAmount: totalAmount?.replaceAll('\$', '').trim(),
    customerName: customerName,
    items: items,
    extractedLines: lines,
  );
}
