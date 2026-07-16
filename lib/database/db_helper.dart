// lib/database/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';

class DBHelper {
  // Singleton pattern to prevent multiple database instances
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zenvyro_invoices.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Create Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        companyName TEXT NOT NULL,
        customerName TEXT NOT NULL,
        date TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        taxRate REAL NOT NULL
      )
    ''');

    // Create Items Table (Linked by Foreign Key)
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
  }

  // --- CRUD OPERATIONS ---

  // 1. Create / Save Invoice
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await instance.database;
    await db.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    for (var item in invoice.items) {
      await db.insert('invoice_items', item.toMap(invoice.id), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // 2. Read All Invoices
  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final invoiceMaps = await db.query('invoices', orderBy: 'date DESC');

    List<Invoice> invoices = [];
    for (var map in invoiceMaps) {
      final String invoiceId = map['id'] as String;
      // Get associated items for this invoice
      final itemMaps = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);

      List<InvoiceItem> items = itemMaps.map((itemMap) => InvoiceItem.fromMap(itemMap)).toList();
      invoices.add(Invoice.fromMap(map, items));
    }
    return invoices;
  }

  // 3. Delete Invoice
  Future<void> deleteInvoice(String id) async {
    final db = await instance.database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
    // Note: Items are automatically deleted because of 'ON DELETE CASCADE'
  }

  // 4. Update Status (e.g., Mark as Paid)
  Future<void> updateInvoiceStatus(String id, String newStatus) async {
    final db = await instance.database;
    await db.update('invoices', {'status': newStatus}, where: 'id = ?', whereArgs: [id]);
  }
}