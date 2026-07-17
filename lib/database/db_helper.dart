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
    _database = await _initDB('zenvyro_invoices_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Create Invoices Table
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
        taxRate REAL NOT NULL
      )
    ''');

    // 2. Create Items Table
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

    // 3. Create Settings Table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        companyName TEXT,
        companyAddress TEXT,
        companyPhone TEXT
      )
    ''');

    // Seed default settings row
    await db.execute('INSERT INTO settings (id, companyName, companyAddress, companyPhone) VALUES (1, "My Company", "", "")');
  }

  // --- SETTINGS CRUD ---

  Future<Map<String, dynamic>> getSettings() async {
    final db = await instance.database;
    final res = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    return res.isNotEmpty ? res.first : {'companyName': 'My Company', 'companyAddress': '', 'companyPhone': ''};
  }

  Future<void> updateSettings(String name, String address, String phone) async {
    final db = await instance.database;
    await db.update('settings', {
      'companyName': name,
      'companyAddress': address,
      'companyPhone': phone
    }, where: 'id = ?', whereArgs: [1]);
  }

  // --- INVOICE CRUD ---

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await instance.database;
    await db.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    for (var item in invoice.items) {
      await db.insert('invoice_items', item.toMap(invoice.id), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final invoiceMaps = await db.query('invoices', orderBy: 'date DESC');

    List<Invoice> invoices = [];
    for (var map in invoiceMaps) {
      final String invoiceId = map['id'] as String;
      final itemMaps = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);

      List<InvoiceItem> items = itemMaps.map((itemMap) => InvoiceItem.fromMap(itemMap)).toList();
      invoices.add(Invoice.fromMap(map, items));
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
}