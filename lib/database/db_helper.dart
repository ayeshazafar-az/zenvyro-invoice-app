// lib/database/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Updated to version 8 to include isFavorite in customers table
    _database = await _initDB('zenvyro_invoices_v8.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
        path,
        version: 8,
        onCreate: _createDB,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 8) {
            await db.execute('DROP TABLE IF EXISTS settings');
            await db.execute('DROP TABLE IF EXISTS invoice_items');
            await db.execute('DROP TABLE IF EXISTS invoices');
            await db.execute('DROP TABLE IF EXISTS customers');
            await db.execute('DROP TABLE IF EXISTS products');
            await _createDB(db, newVersion);
          }
        }
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        companyName TEXT NOT NULL,
        customerName TEXT NOT NULL,
        customerEmail TEXT,
        customerPhone TEXT,
        customerAddress TEXT,
        date TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        taxRate REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        discount REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        companyName TEXT,
        companyAddress TEXT,
        companyPhone TEXT,
        logoPath TEXT,
        currency TEXT,
        defaultTaxRate REAL,
        invoicePrefix TEXT,
        isDarkMode INTEGER DEFAULT 0,
        selectedTemplate TEXT DEFAULT 'Simple'
      )
    ''');

    // --- NEW: Added isFavorite column to customers ---
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO settings (id, companyName, companyAddress, companyPhone, logoPath, currency, defaultTaxRate, invoicePrefix, isDarkMode, selectedTemplate) 
      VALUES (1, "My Company", "", "", "", "\$", 0.0, "INV-", 0, "Simple")
    ''');
  }

  // --- PRODUCT CRUD ---
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<void> insertProduct(String name, double price) async {
    final db = await instance.database;
    await db.insert('products', {'name': name, 'price': price}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProduct(int id) async {
    final db = await instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- CUSTOMER CRUD ---
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await instance.database;
    // --- NEW: Order by isFavorite first, then alphabetically ---
    return await db.query('customers', orderBy: 'isFavorite DESC, name ASC');
  }

  Future<void> insertCustomer(String name, String email, String phone, String address, {int isFavorite = 0}) async {
    final db = await instance.database;
    await db.insert('customers', {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'isFavorite': isFavorite
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- NEW: Method to toggle favorite status ---
  Future<void> toggleCustomerFavorite(int id, int isFavorite) async {
    final db = await instance.database;
    await db.update('customers', {'isFavorite': isFavorite}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await instance.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- SETTINGS CRUD ---
  Future<Map<String, dynamic>> getSettings() async {
    final db = await instance.database;
    final res = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    return res.isNotEmpty ? res.first : {'companyName': 'My Company', 'currency': '\$', 'selectedTemplate': 'Simple'};
  }

  Future<void> updateSettings({
    required String name,
    required String address,
    required String phone,
    required String logoPath,
    required String currency,
    required double defaultTaxRate,
    required String invoicePrefix,
    required bool isDarkMode,
    required String selectedTemplate
  }) async {
    final db = await instance.database;
    await db.update('settings', {
      'companyName': name,
      'companyAddress': address,
      'companyPhone': phone,
      'logoPath': logoPath,
      'currency': currency,
      'defaultTaxRate': defaultTaxRate,
      'invoicePrefix': invoicePrefix,
      'isDarkMode': isDarkMode ? 1 : 0,
      'selectedTemplate': selectedTemplate
    }, where: 'id = ?', whereArgs: [1]);
  }

  // --- INVOICE CRUD ---
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await instance.database;
    await db.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [invoice.id]);
    for (var item in invoice.items) {
      await db.insert('invoice_items', item.toMap(invoice.id), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final invoiceMaps = await db.query('invoices', orderBy: 'date DESC');
    List<Invoice> invoices = [];
    for (var map in invoiceMaps) {
      final itemMaps = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [map['id']]);
      invoices.add(Invoice.fromMap(map, itemMaps.map((i) => InvoiceItem.fromMap(i)).toList()));
    }
    return invoices;
  }

  Future<void> deleteInvoice(String id) async {
    final db = await instance.database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateInvoiceStatus(String id, String newStatus) async {
    final db = await instance.database;
    await db.update('invoices', {'status': newStatus}, where: 'id = ?', whereArgs: [id]);
  }

  // --- NEW: Added for Restore Functionality ---
  Future<void> closeAndResetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}