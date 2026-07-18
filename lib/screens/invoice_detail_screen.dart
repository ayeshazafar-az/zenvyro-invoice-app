// lib/screens/invoice_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

import '../models/invoice_model.dart';
import '../services/invoice_provider.dart';
import '../pdf/pdf_invoice_api.dart';
import 'create_invoice_screen.dart'; // Added to navigate to Edit/Duplicate

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.id}'),
        actions: [
          // --- PDF Preview / Print Button ---
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
            onPressed: () async {
              final pdfBytes = await PdfInvoiceApi.generate(invoice);
              await Printing.layoutPdf(onLayout: (format) => pdfBytes);
            },
          ),

          // --- Native Share Button ---
          IconButton(
            icon: const Icon(Icons.share, color: Colors.greenAccent),
            onPressed: () async {
              final pdfBytes = await PdfInvoiceApi.generate(invoice);
              final output = await getTemporaryDirectory();
              final file = File('${output.path}/Invoice_${invoice.id}.pdf');
              await file.writeAsBytes(pdfBytes);

              await Share.shareXFiles(
                [XFile(file.path)],
                text: 'Here is your invoice #${invoice.id}.',
              );
            },
          ),

          // --- Options Menu (Edit, Duplicate, Delete) ---
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                // Navigate to Create Screen in Edit Mode
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateInvoiceScreen(existingInvoice: invoice))
                );
              } else if (value == 'duplicate') {
                // Navigate to Create Screen in Duplicate Mode
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateInvoiceScreen(existingInvoice: invoice, isDuplicate: true))
                );
              } else if (value == 'delete') {
                // 1. Show the Confirmation Dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Invoice'),
                      content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), // Cancel
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), // Confirm
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );

                // 2. If confirmed, delete and go back
                if (confirm == true) {
                  if (context.mounted) {
                    await Provider.of<InvoiceProvider>(context, listen: false).deleteInvoice(invoice.id);
                    Navigator.pop(context);
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))
              ),
              const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(leading: Icon(Icons.copy), title: Text('Duplicate'))
              ),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: ListTile(
                title: const Text('Status'),
                trailing: DropdownButton<String>(
                  value: invoice.status,
                  items: ['Paid', 'Unpaid', 'Overdue'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      Provider.of<InvoiceProvider>(context, listen: false).updateStatus(invoice.id, newStatus);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Customer Info
            Text('Customer Details', style: Theme.of(context).textTheme.titleLarge),
            ListTile(title: Text(invoice.customerName), subtitle: Text(invoice.customerEmail)),
            ListTile(title: Text(invoice.customerPhone), subtitle: Text(invoice.customerAddress)),
            const Divider(),
            // Items
            Text('Items', style: Theme.of(context).textTheme.titleLarge),
            ...invoice.items.map((item) => ListTile(
              title: Text(item.name),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: Text('\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}'),
            )),
            const Divider(),
            ListTile(
              title: const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('\$${invoice.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}