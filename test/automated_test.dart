import 'package:flutter_test/flutter_test.dart';
import '../lib/script.dart';
import 'package:intl/intl.dart';

void main() {
  test('Verify Refactored Extraction Logic', () async {
    final String filePath = 'assets/demo_invoice.pdf';
    final data = await extractInvoiceData(filePath);
    
    print('Extracted Invoice #: ${data.invoiceNumber}');
    print('Extracted Total: ${data.totalAmount}');
    print('Extracted Items Count: ${data.items.length}');
    
    expect(data.invoiceNumber, isNotNull);
    expect(data.totalAmount, equals('22.00')); // Stripped $
    expect(data.items.length, greaterThan(0));
    
    // Check item values
    expect(data.items[0].price, equals('1.00'));
    expect(data.items[1].price, equals('20.00'));
    
    // Test Date Formatting (logic inside the page)
    String formatDate(String? dateStr) {
      if (dateStr == null) return DateFormat('yyyy-MM-dd').format(DateTime.now());
      try {
        final date = DateFormat('dd MMM yyyy').parse(dateStr);
        return DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        return 'FAIL';
      }
    }
    
    expect(formatDate(data.date), equals('2026-03-10'));
    expect(formatDate(data.dueDate), equals('2026-03-19'));
    print('✓ All verification checks passed!');
  });
}
