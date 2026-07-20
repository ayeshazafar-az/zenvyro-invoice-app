// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import '../widgets/summary_card.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';
import 'settings_screen.dart';
import 'customer_list_screen.dart';
import 'product_catalog_screen.dart';
import 'monthly_summary_screen.dart';
import 'revenue_chart_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'All';

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

          // Apply status filter logic
          var displayList = provider.filteredInvoices;
          if (_selectedFilter != 'All') {
            displayList = displayList.where((inv) {
              return inv.status.toLowerCase() == _selectedFilter.toLowerCase();
            }).toList();
          }

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

                      // --- NEW: 2x2 Grid using SummaryCard Widget ---
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'Total Revenue',
                              value: currencyFormat.format(provider.totalRevenue),
                              bgColor: Theme.of(context).colorScheme.primaryContainer,
                              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'Total Invoices',
                              value: provider.totalInvoices.toString(),
                              bgColor: Colors.blue.shade100,
                              textColor: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'Paid Invoices',
                              value: provider.paidInvoices.toString(),
                              bgColor: Colors.green.shade100,
                              textColor: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'Unpaid / Overdue',
                              value: provider.unpaidInvoices.toString(),
                              bgColor: Colors.red.shade100,
                              textColor: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Revenue Chart Card in Body ---
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
                      const SizedBox(height: 16),

                      // --- Status Filter Chips Bar ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Paid', 'Unpaid', 'Overdue'].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Invoices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              displayList.isEmpty
                  ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text('No invoices found for "$_selectedFilter".', style: const TextStyle(color: Colors.grey)),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final invoice = displayList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.receipt),
                      ),
                      title: Text(invoice.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${invoice.id} • Due: ${invoice.dueDate}'),
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
                              color: invoice.status == 'Paid'
                                  ? Colors.green
                                  : invoice.status == 'Overdue'
                                  ? Colors.red
                                  : Colors.orange,
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
                  childCount: displayList.length,
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