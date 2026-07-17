// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';
import 'settings_screen.dart'; // <--- ADDED IMPORT

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This formatter makes double values look like "$1,250.00"
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to Settings Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      // The Consumer widget listens to the Provider and redraws ONLY this section when data changes
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.invoices.isEmpty) {
            return _buildEmptyState(context);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Search Bar ---
                      TextField(
                        onChanged: (value) => Provider.of<InvoiceProvider>(context, listen: false).searchInvoices(value),
                        decoration: InputDecoration(
                          hintText: 'Search by Name or ID...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Summary Statistics ---
                      _buildSummaryCard(
                        context,
                        'Total Revenue',
                        currencyFormat.format(provider.totalRevenue),
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Paid',
                              provider.paidInvoices.toString(),
                              Colors.green.shade100,
                              Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Unpaid/Overdue',
                              provider.unpaidInvoices.toString(),
                              Colors.red.shade100,
                              Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Invoices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // --- Invoice List ---
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    // Using filteredInvoices here
                    final invoice = provider.filteredInvoices[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.receipt),
                      ),
                      title: Text(invoice.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${invoice.id} • ${invoice.date}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(invoice.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            invoice.status,
                            style: TextStyle(
                              color: invoice.status == 'Paid' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceDetailScreen(invoice: invoice),
                          ),
                        );
                      },
                    );
                  },
                  // Using filteredInvoices length here
                  childCount: provider.filteredInvoices.length,
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Invoice'),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSummaryCard(BuildContext context, String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('No Invoices Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first invoice.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}