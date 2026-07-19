// lib/screens/revenue_chart_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/invoice_provider.dart';
import '../database/db_helper.dart';

class RevenueChartScreen extends StatelessWidget {
  const RevenueChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Insights')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: DBHelper.instance.getSettings(),
          builder: (context, snapshot) {
            final String currency = snapshot.data?['currency'] ?? '\$';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<InvoiceProvider>(
                builder: (context, provider, _) {
                  final data = provider.monthlyRevenue;

                  if (data.isEmpty) {
                    return const Center(
                      child: Text(
                        'No revenue data yet.\nCreate some paid invoices to see your charts!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final keys = data.keys.toList();
                  final bars = keys.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: data[e.value]!,
                          color: Theme.of(context).colorScheme.primary,
                          width: 24, // Made the bars slightly thicker
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Monthly Revenue Overview',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32.0, right: 32.0, left: 16.0, bottom: 24.0),
                            child: BarChart(
                              BarChartData(
                                barGroups: bars,
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        if (val.toInt() >= 0 && val.toInt() < keys.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              keys[val.toInt()],
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 32,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      getTitlesWidget: (val, meta) {
                                        if (val == 0) return const Text('');
                                        // Abbreviate large numbers for a cleaner Y-axis
                                        String formattedVal = val >= 1000
                                            ? '${(val / 1000).toStringAsFixed(1)}k'
                                            : val.toInt().toString();
                                        return Text(
                                          '$currency$formattedVal',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.2),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false), // Hide the default box border

                                // --- NEW: Tap interaction for exact amounts ---
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.blueGrey.shade800,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '$currency${rod.toY.toStringAsFixed(2)}',
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }
      ),
    );
  }
}