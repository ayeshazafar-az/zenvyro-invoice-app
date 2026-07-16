// lib/services/invoice_provider.dart

import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;

  // Getters for the UI to read the data
  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  // --- Dashboard Statistics ---
  int get totalInvoices => _invoices.length;

  int get paidInvoices => _invoices.where((inv) => inv.status == 'Paid').length;

  int get unpaidInvoices => _invoices.where((inv) => inv.status == 'Unpaid' || inv.status == 'Overdue').length;

  double get totalRevenue => _invoices
      .where((inv) => inv.status == 'Paid')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  // --- Core Functions ---

  // 1. Load data from SQLite when the app opens
  Future<void> fetchInvoices() async {
    _isLoading = true;
    notifyListeners();

    _invoices = await DBHelper.instance.getAllInvoices();

    _isLoading = false;
    notifyListeners(); // Tells the UI to rebuild
  }

  // 2. Save a new invoice to SQLite and update the screen
  Future<void> addInvoice(Invoice invoice) async {
    await DBHelper.instance.insertInvoice(invoice);
    _invoices.insert(0, invoice); // Add to the top of the list
    notifyListeners();
  }

  // 3. Delete an invoice and remove it from the screen
  Future<void> deleteInvoice(String id) async {
    await DBHelper.instance.deleteInvoice(id);
    _invoices.removeWhere((inv) => inv.id == id);
    notifyListeners();
  }

  // 4. Update the status (e.g., mark an unpaid invoice as 'Paid')
  Future<void> updateStatus(String id, String newStatus) async {
    await DBHelper.instance.updateInvoiceStatus(id, newStatus);

    final index = _invoices.indexWhere((inv) => inv.id == id);
    if (index != -1) {
      final oldInv = _invoices[index];
      // Create a copy of the invoice with the new status
      _invoices[index] = Invoice(
        id: oldInv.id,
        companyName: oldInv.companyName,
        customerName: oldInv.customerName,
        date: oldInv.date,
        dueDate: oldInv.dueDate,
        status: newStatus,
        taxRate: oldInv.taxRate,
        items: oldInv.items,
      );
      notifyListeners();
    }
  }
}