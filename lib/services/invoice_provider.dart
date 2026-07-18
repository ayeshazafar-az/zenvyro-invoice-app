// lib/services/invoice_provider.dart

import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  String _searchQuery = '';
  bool _isLoading = false;

  // --- NEW: Currency Variable ---
  String _currencySymbol = '\$';
  String get currencySymbol => _currencySymbol;

  // Getters
  List<Invoice> get invoices => _invoices;

  // Return filtered list if searching, otherwise return all
  List<Invoice> get filteredInvoices => _searchQuery.isEmpty ? _invoices : _filteredInvoices;

  bool get isLoading => _isLoading;

  // --- Dashboard Statistics ---
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

    // --- NEW: Fetch Currency from Settings ---
    final settings = await DBHelper.instance.getSettings();
    _currencySymbol = settings['currency'] ?? '\$';

    _isLoading = false;
    notifyListeners();
  }

  // --- NEW: Refresh Settings Method ---
  Future<void> refreshSettings() async {
    final settings = await DBHelper.instance.getSettings();
    _currencySymbol = settings['currency'] ?? '\$';
    notifyListeners(); // Tells the UI to update the symbol immediately
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
        notes: oldInv.notes, // --- ADDED THIS LINE HERE ---
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