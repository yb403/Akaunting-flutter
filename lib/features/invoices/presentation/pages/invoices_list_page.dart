import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/invoice_cubit.dart';
import '../../cubit/invoice_state.dart';
import '../../models/invoice.dart';
import 'create_invoice_page.dart';
import 'extract_and_create_invoice_page.dart';
import 'extract_image_invoice_page.dart';

import '../../../../core/widgets/common_app_bar.dart';

class InvoicesListPage extends StatelessWidget {
  const InvoicesListPage({super.key});

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Invoice',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(Icons.edit, color: Colors.deepPurple),
                ),
                title: const Text('Manual Entry'),
                subtitle: const Text('Fill in invoice details manually'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateInvoicePage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.shade100,
                  child: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
                ),
                title: const Text('Import from PDF'),
                subtitle: const Text('Extract invoice data from a PDF file'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExtractAndCreateInvoicePage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.image, color: Colors.orange),
                ),
                title: const Text('Import from Image (OCR)'),
                subtitle: const Text('Scan an image to extract invoice data'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExtractImageInvoicePage()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvoiceCubit()..fetchInvoices(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: const CommonAppBar(title: 'Invoices'),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showCreateOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('New Invoice'),
            ),
            body: BlocBuilder<InvoiceCubit, InvoiceState>(
              builder: (context, state) {
                if (state is InvoiceLoading || state is InvoiceInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is InvoiceError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.deepPurple, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<InvoiceCubit>().fetchInvoices();
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  );
                } else if (state is InvoiceLoaded) {
                  if (state.invoices.isEmpty) {
                    return const Center(child: Text('No invoices found.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<InvoiceCubit>().fetchInvoices();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: state.invoices.length,
                      itemBuilder: (context, index) {
                        Invoice invoice = state.invoices[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(
                              invoice.documentNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client: ${invoice.contactName}'),
                                Text('Issued: ${invoice.issuedAt}'),
                                Text(
                                  'Status: ${invoice.status.toUpperCase()}',
                                  style: TextStyle(
                                    color: invoice.status == 'paid' ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${invoice.amount.toStringAsFixed(2)}\n${invoice.currencyCode}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
  }
}
