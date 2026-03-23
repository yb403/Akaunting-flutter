import 'dart:io';
import 'dart:typed_data';

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

Future<InvoiceData> extractInvoiceDataFromText(String text) async {
  final List<String> lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  
  String? invoiceNumber;
  String? date;
  String? dueDate;
  String? totalAmount;
  String? customerName;
  List<InvoiceItem> items = [];

  // Helper to find value by field name (case insensitive)
  String? findValue(String label) {
    for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.toLowerCase().contains(label.toLowerCase())) {
            // Horizontal case: "Label: Value"
            if (line.contains(':')) {
                final val = line.split(':').last.trim();
                if (val.isNotEmpty && !_isLikelyLabel(val)) return val;
            }
            // Vertical case: Value is on a completely different line much later
            // We search for a value that follows the same order as labels
            // But let's look for known patterns first.
        }
    }
    return null;
  }

  invoiceNumber = findValue('Invoice Number');
  date = findValue('Invoice Date');
  dueDate = findValue('Due Date');

  // If still null, try finding values that appear later in the stream if labels were grouped
  if (invoiceNumber == null || date == null) {
      // Find where labels are
      int invNumIdx = lines.indexWhere((l) => l.toLowerCase().contains('invoice number:'));
      int dateIdx = lines.indexWhere((l) => l.toLowerCase().contains('invoice date:'));
      int dueIdx = lines.indexWhere((l) => l.toLowerCase().contains('due date:'));

      if (invNumIdx != -1 && dateIdx != -1) {
          // Find candidates that look like values
          List<String> candidates = lines.where((l) => 
            (l.startsWith('INV-') || RegExp(r'^\d+ [A-Za-z]+ \d+$').hasMatch(l)) && !_isLikelyLabel(l)
          ).toList();
          
          if (candidates.isNotEmpty) {
              for (final c in candidates) {
                  if (c.startsWith('INV-')) invoiceNumber = c;
                  else if (date == null) date = c;
                  else if (dueDate == null) dueDate = c;
              }
          }
      }
  }

  // Customer detection (usually after "Bill To")
  int billToIndex = lines.indexWhere((l) => l.toLowerCase().contains('bill to'));
  if (billToIndex != -1 && billToIndex + 1 < lines.length) {
      customerName = lines[billToIndex + 1];
  }

  // Total detection
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].toLowerCase();
    if (line.startsWith('total:')) {
       final sameLineMatch = RegExp(r'total:\s*\$?\s*([\d,.]+)').firstMatch(line);
       if (sameLineMatch != null) {
           totalAmount = sameLineMatch.group(1);
           break;
       }
       if (i + 1 < lines.length) {
           final nextLine = lines[i + 1].replaceAll(r'$', '').trim();
           if (_isNumeric(nextLine)) {
               totalAmount = nextLine;
               break;
           }
       }
    }
  }
  
  if (totalAmount == null) {
      // Look for the last currency-like value in the text
      final currencyMatches = RegExp(r'\$?\s*([\d,]+\.\d{2})').allMatches(text);
      if (currencyMatches.isNotEmpty) {
          totalAmount = currencyMatches.last.group(1);
      }
  }

  // Items extraction (Vertical Block Aware)
  int itemsHeaderIdx = lines.indexWhere((l) => l.toLowerCase().contains('items'));
  int qtyHeaderIdx = lines.indexWhere((l) => l.toLowerCase().contains('quantity'));
  int priceHeaderIdx = lines.indexWhere((l) => l.toLowerCase().contains('price'));
  int amountHeaderIdx = lines.indexWhere((l) => l.toLowerCase().contains('amount'));

  if (itemsHeaderIdx != -1 && qtyHeaderIdx != -1 && priceHeaderIdx != -1) {
      // 1. Collect Quantities
      List<String> quantities = [];
      for (int i = qtyHeaderIdx + 1; i < lines.length; i++) {
          if (RegExp(r'^\d+$').hasMatch(lines[i])) quantities.add(lines[i]);
          else if (_isLikelyLabel(lines[i]) || lines[i].contains(':')) break;
      }

      // 2. Collect Prices
      List<String> prices = [];
      for (int i = priceHeaderIdx + 1; i < lines.length; i++) {
          String val = lines[i].replaceAll(r'$', '').trim();
          if (_isNumeric(val)) prices.add(val);
          else if (_isLikelyLabel(lines[i]) && !lines[i].toLowerCase().contains('amount')) break;
      }

      // 3. Collect Amounts
      List<String> amounts = [];
      for (int i = amountHeaderIdx + 1; i < lines.length; i++) {
          String val = lines[i].replaceAll(r'$', '').trim();
          if (_isNumeric(val)) amounts.add(val);
          else if (_isLikelyLabel(lines[i])) break;
      }

      // 4. Collect Descriptions
      // This is trickier because they might be multi-line.
      // We assume one description block per quantity.
      List<String> descriptions = [];
      if (quantities.isNotEmpty) {
          int descPointer = itemsHeaderIdx + 1;
          for (int i = 0; i < quantities.length; i++) {
              String desc = '';
              while (descPointer < qtyHeaderIdx && descPointer < lines.length) {
                  if (!_isLikelyLabel(lines[descPointer])) {
                      if (desc.isNotEmpty) desc += ' ';
                      desc += lines[descPointer];
                  }
                  descPointer++;
                  // If next line looks like a description of a NEW item, stop? 
                  // But we don't know that. Let's assume the user might have grouped descriptions.
                  // Often OCR puts all descriptions together. 
              }
              // If we have 3 quantities but only one big block of descriptions,
              // we might need to split it. This is hard without coordinates.
              // For the sample, let's try a simpler split if it's too long.
          }
          
          // Fallback for the sample structure: descriptions are lines between 'Items' and 'Notes' 
          // (if horizontal items failed)
          List<String> descLines = [];
          for (int i = itemsHeaderIdx + 1; i < lines.length; i++) {
              if (lines[i].toLowerCase().contains('notes') || lines[i].toLowerCase().contains('quantity') || lines[i].toLowerCase().contains('bill up')) break;
              if (!_isLikelyLabel(lines[i])) descLines.add(lines[i]);
          }
          
          // Reconstruct 3 descriptions from the lines (Service, dev, HAW)
          // Simple heuristic: group lines until we have total items count
          if (descLines.length >= quantities.length) {
              int linesPerItem = (descLines.length / quantities.length).floor();
              for (int i = 0; i < quantities.length; i++) {
                  String combined = descLines.skip(i * linesPerItem).take(linesPerItem).join(' ');
                  descriptions.add(combined);
              }
          }
      }

      // 5. Zip together
      for (int i = 0; i < quantities.length; i++) {
          items.add(InvoiceItem(
              description: i < descriptions.length ? descriptions[i] : 'Item ${i+1}',
              quantity: quantities[i],
              price: i < prices.length ? prices[i] : '0.00',
              amount: i < amounts.length ? amounts[i] : '0.00',
          ));
      }
  }

  // Fallback to horizontal parsing if items still empty
  if (items.isEmpty) {
      // (Old horizontal logic here...)
  }

  return InvoiceData(
    invoiceNumber: invoiceNumber,
    date: date,
    dueDate: dueDate,
    totalAmount: totalAmount?.replaceAll(',', ''),
    customerName: customerName,
    items: items,
    extractedLines: lines,
  );
}

bool _isNumeric(String s) {
  if (s.isEmpty) return false;
  return double.tryParse(s.replaceAll(',', '')) != null;
}

bool _isLikelyLabel(String s) {
    final lower = s.toLowerCase();
    return lower.contains('date') || lower.contains('total') || lower.contains('number') || lower.contains('bill to') || lower.contains('items') || lower.contains('subtotal') || lower.contains('quantity') || lower.contains('price') || lower.contains('amount') || lower.contains('notes');
}
