// lib/screens/customer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/invoice_provider.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer History')),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.customers.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }
          return ListView.builder(
            itemCount: provider.customers.length,
            itemBuilder: (context, index) {
              final customer = provider.customers[index];
              final isFavorite = (customer['isFavorite'] ?? 0) == 1;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFavorite ? Colors.amber.shade100 : Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    customer['name'][0].toUpperCase(),
                    style: TextStyle(
                      color: isFavorite ? Colors.amber.shade900 : Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  customer['email']?.isNotEmpty == true ? customer['email'] : 'No email provided',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () => provider.toggleCustomerFavorite(
                        customer['id'],
                        customer['isFavorite'] ?? 0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteCustomer(customer['id']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}