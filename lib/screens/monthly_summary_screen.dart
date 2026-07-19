// lib/screens/monthly_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/invoice_provider.dart';

class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Income Summary')),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          final data = provider.monthlyRevenue;

          if (data.isEmpty) {
            return const Center(child: Text('No revenue data available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final month = data.keys.toList()[index];
              final amount = data[month];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.calendar_month),
                ),
                title: Text(month, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  '${provider.currencySymbol}${amount?.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}