// lib/models/invoice_model.dart

class InvoiceItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double discount;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get total => (quantity * unitPrice) - discount;

  Map<String, dynamic> toMap(String invoiceId) => {
    'id': id,
    'invoiceId': invoiceId,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
  };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final String id;
  final String companyName;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final String date;
  final String dueDate;
  final String _status; // Raw status stored in DB
  final double taxRate;
  final String notes;
  List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.companyName,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    required this.date,
    required this.dueDate,
    required String status,
    required this.taxRate,
    required this.notes,
    required this.items,
  }) : _status = status;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get grandTotal => subtotal + taxAmount;

  // Dynamic getter: Automatically evaluates to 'Overdue' if due date is today or past (and not Paid)
  String get status {
    if (_status == 'Paid') return 'Paid';
    try {
      if (dueDate.isNotEmpty) {
        final due = DateTime.parse(dueDate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDay = DateTime(due.year, due.month, due.day);
        if (today.compareTo(dueDay) >= 0) {
          return 'Overdue';
        }
      }
    } catch (_) {}
    return _status;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'companyName': companyName,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'customerAddress': customerAddress,
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'taxRate': taxRate,
    'notes': notes,
  };

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerEmail: map['customerEmail']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      customerAddress: map['customerAddress']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dueDate: map['dueDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Unpaid',
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes']?.toString() ?? '',
      items: items,
    );
  }
}