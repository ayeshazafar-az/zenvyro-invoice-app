// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';
import 'settings_screen.dart';
import 'customer_list_screen.dart';
import 'product_catalog_screen.dart';
import 'monthly_summary_screen.dart';
import 'revenue_chart_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RevenueChartScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MonthlySummaryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductCatalogScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (context.mounted) {
                Provider.of<InvoiceProvider>(context, listen: false).refreshSettings();
              }
            },
          )
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.invoices.isEmpty) {
            return _buildEmptyState(context);
          }

          final currencyFormat = NumberFormat.currency(symbol: '${provider.currencySymbol} ', decimalDigits: 2);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 16),

                      // --- NEW: Revenue Chart Card in Body ---
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: const Text('View Revenue Charts', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Analyze your monthly income trends'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RevenueChartScreen()),
                            );
                          },
                        ),
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
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

  Widget _buildSummaryCard(BuildContext context, String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
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