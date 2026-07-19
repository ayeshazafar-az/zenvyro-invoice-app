// lib/services/invoice_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  String _searchQuery = '';
  bool _isLoading = false;

  String _currencySymbol = '\$';
  bool _isDarkMode = false;
  String _selectedTemplate = 'Simple';

  String get currencySymbol => _currencySymbol;
  bool get isDarkMode => _isDarkMode;
  String get selectedTemplate => _selectedTemplate;

  List<Invoice> get invoices => _invoices;
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get products => _products;

  List<Invoice> get filteredInvoices => _searchQuery.isEmpty ? _invoices : _filteredInvoices;
  bool get isLoading => _isLoading;

  // --- Statistics ---
  int get totalInvoices => _invoices.length;
  int get paidInvoices => _invoices.where((inv) => inv.status == 'Paid').length;
  int get unpaidInvoices => _invoices.where((inv) => inv.status == 'Unpaid' || inv.status == 'Overdue').length;

  double get totalRevenue => _invoices
      .where((inv) => inv.status == 'Paid')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  // --- Monthly Revenue Logic ---
  Map<String, double> get monthlyRevenue {
    final Map<String, double> revenueByMonth = {};

    for (var inv in _invoices.where((i) => i.status == 'Paid')) {
      try {
        final date = DateTime.parse(inv.date);
        final monthKey = DateFormat('MMM yyyy').format(date);
        revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0.0) + inv.grandTotal;
      } catch (e) {
        continue;
      }
    }
    return revenueByMonth;
  }

  void searchInvoices(String query) {
    _searchQuery = query;
    _filteredInvoices = query.isEmpty ? [] : _invoices.where((inv) =>
    inv.customerName.toLowerCase().contains(query.toLowerCase()) ||
        inv.id.toLowerCase().contains(query.toLowerCase())
    ).toList();
    notifyListeners();
  }

  Future<void> fetchInvoices() async {
    _isLoading = true;
    notifyListeners();

    _invoices = await DBHelper.instance.getAllInvoices();
    _customers = await DBHelper.instance.getCustomers();
    _products = await DBHelper.instance.getProducts();

    final settings = await DBHelper.instance.getSettings();
    _currencySymbol = settings['currency'] ?? '\$';
    _isDarkMode = (settings['isDarkMode'] ?? 0) == 1;
    _selectedTemplate = settings['selectedTemplate'] ?? 'Simple';

    _isLoading = false;
    notifyListeners();
  }

  // --- Product Management ---
  Future<void> addProduct(String name, double price) async {
    await DBHelper.instance.insertProduct(name, price);
    _products = await DBHelper.instance.getProducts();
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await DBHelper.instance.deleteProduct(id);
    _products = await DBHelper.instance.getProducts();
    notifyListeners();
  }

  // --- Customer Management ---
  Future<void> addCustomer(String name, String email, String phone, String address) async {
    await DBHelper.instance.insertCustomer(name, email, phone, address);
    _customers = await DBHelper.instance.getCustomers();
    notifyListeners();
  }

  Future<void> deleteCustomer(int id) async {
    await DBHelper.instance.deleteCustomer(id);
    _customers = await DBHelper.instance.getCustomers();
    notifyListeners();
  }

  // --- NEW: Toggle Customer Favorite ---
  Future<void> toggleCustomerFavorite(int id, int currentStatus) async {
    final newStatus = currentStatus == 1 ? 0 : 1;
    await DBHelper.instance.toggleCustomerFavorite(id, newStatus);
    _customers = await DBHelper.instance.getCustomers(); // Refresh to update sorting
    notifyListeners();
  }

  // --- Settings & Invoice Logic ---
  Future<void> refreshSettings() async {
    final settings = await DBHelper.instance.getSettings();
    _currencySymbol = settings['currency'] ?? '\$';
    _isDarkMode = (settings['isDarkMode'] ?? 0) == 1;
    _selectedTemplate = settings['selectedTemplate'] ?? 'Simple';
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final settings = await DBHelper.instance.getSettings();
    await DBHelper.instance.updateSettings(
      name: settings['companyName'] ?? 'My Company',
      address: settings['companyAddress'] ?? '',
      phone: settings['companyPhone'] ?? '',
      logoPath: settings['logoPath'] ?? '',
      currency: settings['currency'] ?? '\$',
      defaultTaxRate: settings['defaultTaxRate'] ?? 0.0,
      invoicePrefix: settings['invoicePrefix'] ?? 'INV-',
      isDarkMode: _isDarkMode,
      selectedTemplate: _selectedTemplate,
    );
    notifyListeners();
  }

  // --- Update Template ---
  Future<void> updateTemplate(String newTemplate) async {
    _selectedTemplate = newTemplate;
    final settings = await DBHelper.instance.getSettings();
    await DBHelper.instance.updateSettings(
      name: settings['companyName'] ?? 'My Company',
      address: settings['companyAddress'] ?? '',
      phone: settings['companyPhone'] ?? '',
      logoPath: settings['logoPath'] ?? '',
      currency: settings['currency'] ?? '\$',
      defaultTaxRate: settings['defaultTaxRate'] ?? 0.0,
      invoicePrefix: settings['invoicePrefix'] ?? 'INV-',
      isDarkMode: _isDarkMode,
      selectedTemplate: _selectedTemplate,
    );
    notifyListeners();
  }

  Future<void> addInvoice(Invoice invoice) async {
    await DBHelper.instance.insertInvoice(invoice);
    _invoices.insert(0, invoice);
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    await DBHelper.instance.deleteInvoice(id);
    _invoices.removeWhere((inv) => inv.id == id);
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await DBHelper.instance.updateInvoiceStatus(id, newStatus);
    final index = _invoices.indexWhere((inv) => inv.id == id);
    if (index != -1) {
      final oldInv = _invoices[index];
      _invoices[index] = Invoice(
        id: oldInv.id, companyName: oldInv.companyName, customerName: oldInv.customerName,
        customerEmail: oldInv.customerEmail, customerPhone: oldInv.customerPhone,
        customerAddress: oldInv.customerAddress, date: oldInv.date, dueDate: oldInv.dueDate,
        status: newStatus, taxRate: oldInv.taxRate, notes: oldInv.notes, items: oldInv.items,
      );
      notifyListeners();
    }
  }
}