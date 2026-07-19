// lib/screens/invoice_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart'; // NEW: Imported to show QR code

import '../models/invoice_model.dart';
import '../services/invoice_provider.dart';
import '../utils/pdf_generator.dart';
import '../database/db_helper.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>>(
      future: DBHelper.instance.getSettings(),
      builder: (context, snapshot) {
        final String currency = snapshot.data?['currency'] ?? '\$';

        return Scaffold(
          appBar: AppBar(
            title: Text('Invoice ${invoice.id}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
                onPressed: () async {
                  await PdfGenerator.generateAndPrint(invoice, provider.selectedTemplate);
                },
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.orangeAccent),
                onPressed: () async {
                  try {
                    final pdfBytes = await PdfGenerator.generate(invoice, provider.selectedTemplate);
                    Directory? directory = Platform.isAndroid
                        ? await getExternalStorageDirectory()
                        : await getApplicationDocumentsDirectory();
                    if (directory != null) {
                      final file = File('${directory.path}/Invoice_${invoice.id}.pdf');
                      await file.writeAsBytes(pdfBytes);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: ${file.path}'), backgroundColor: Colors.green));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.greenAccent),
                onPressed: () async {
                  final pdfBytes = await PdfGenerator.generate(invoice, provider.selectedTemplate);
                  final output = await getTemporaryDirectory();
                  final file = File('${output.path}/Invoice_${invoice.id}.pdf');
                  await file.writeAsBytes(pdfBytes);
                  await Share.shareXFiles([XFile(file.path)], text: 'Here is your invoice #${invoice.id}.');
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInvoiceScreen(existingInvoice: invoice)));
                  } else if (value == 'duplicate') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInvoiceScreen(existingInvoice: invoice, isDuplicate: true)));
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete Invoice'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
                    if (confirm == true && context.mounted) {
                      await Provider.of<InvoiceProvider>(context, listen: false).deleteInvoice(invoice.id);
                      Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                  const PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy), title: Text('Duplicate'))),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Status'),
                    trailing: DropdownButton<String>(
                      value: invoice.status,
                      items: ['Paid', 'Unpaid', 'Overdue'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (s) => s != null ? Provider.of<InvoiceProvider>(context, listen: false).updateStatus(invoice.id, s) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Customer Details', style: Theme.of(context).textTheme.titleLarge),
                ListTile(title: const Text('Name', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(invoice.customerName, style: const TextStyle(fontSize: 16))),
                ListTile(title: const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(invoice.customerEmail.isNotEmpty ? invoice.customerEmail : 'N/A', style: const TextStyle(fontSize: 16))),
                ListTile(title: const Text('Phone', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(invoice.customerPhone.isNotEmpty ? invoice.customerPhone : 'N/A', style: const TextStyle(fontSize: 16))),
                ListTile(title: const Text('Address', style: TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(invoice.customerAddress.isNotEmpty ? invoice.customerAddress : 'N/A', style: const TextStyle(fontSize: 16))),
                const Divider(),
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
                ...invoice.items.map((item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text('Qty: ${item.quantity}'),
                  trailing: Text('$currency${(item.unitPrice * item.quantity).toStringAsFixed(2)}'),
                )),
                const Divider(),
                ListTile(
                  title: const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('$currency${invoice.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),

                // --- NEW: QR Code Display UI ---
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      const Text('Scan to Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      QrImageView(
                        data: "https://paypal.me/yourusername/${invoice.grandTotal}",
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}