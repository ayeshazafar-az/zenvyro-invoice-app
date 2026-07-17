// lib/services/invoice_provider.dart

import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = []; // New list for search results
  String _searchQuery = '';             // New variable to track search input
  bool _isLoading = false;

  // Getters
  List<Invoice> get invoices => _invoices;

  // Return filtered list if searching, otherwise return all
  List<Invoice> get filteredInvoices => _searchQuery.isEmpty ? _invoices : _filteredInvoices;

  bool get isLoading => _isLoading;

  // --- Dashboard Statistics ---
  // We use _invoices here to ensure statistics are always based on ALL data
  int get totalInvoices => _invoices.length;

  int get paidInvoices => _invoices.where((inv) => inv.status == 'Paid').length;

  int get unpaidInvoices => _invoices.where((inv) => inv.status == 'Unpaid' || inv.status == 'Overdue').length;

  double get totalRevenue => _invoices
      .where((inv) => inv.status == 'Paid')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  // --- Search Logic ---
  void searchInvoices(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredInvoices = [];
    } else {
      _filteredInvoices = _invoices.where((inv) =>
      inv.customerName.toLowerCase().contains(query.toLowerCase()) ||
          inv.id.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // --- Core Functions ---

  Future<void> fetchInvoices() async {
    _isLoading = true;
    notifyListeners();

    _invoices = await DBHelper.instance.getAllInvoices();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addInvoice(Invoice invoice) async {
    await DBHelper.instance.insertInvoice(invoice);
    _invoices.insert(0, invoice);
    _searchQuery = ''; // Reset search when adding
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    await DBHelper.instance.deleteInvoice(id);
    _invoices.removeWhere((inv) => inv.id == id);
    _searchQuery = ''; // Reset search when deleting
    notifyListeners();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await DBHelper.instance.updateInvoiceStatus(id, newStatus);

    final index = _invoices.indexWhere((inv) => inv.id == id);
    if (index != -1) {
      final oldInv = _invoices[index];
      _invoices[index] = Invoice(
        id: oldInv.id,
        companyName: oldInv.companyName,
        customerName: oldInv.customerName,
        customerEmail: oldInv.customerEmail,
        customerPhone: oldInv.customerPhone,
        customerAddress: oldInv.customerAddress,
        date: oldInv.date,
        dueDate: oldInv.dueDate,
        status: newStatus,
        taxRate: oldInv.taxRate,
        items: oldInv.items,
      );

      // Refresh the search results if we are currently searching
      if (_searchQuery.isNotEmpty) {
        searchInvoices(_searchQuery);
      } else {
        notifyListeners();
      }
    }
  }
}