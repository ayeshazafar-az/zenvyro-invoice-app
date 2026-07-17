// lib/screens/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../services/invoice_provider.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await Provider.of<InvoiceProvider>(context, listen: false).deleteInvoice(invoice.id);
              Navigator.pop(context);
            },
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