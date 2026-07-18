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
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
      discount: map['discount'],
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
  final String status;
  final double taxRate;
  final String notes; // --- ADDED FOR NOTES & INSTRUCTIONS ---
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
    required this.status,
    required this.taxRate,
    required this.notes, // --- ADDED TO CONSTRUCTOR ---
    required this.items,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get grandTotal => subtotal + taxAmount;

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
    'notes': notes, // --- ADDED TO MAP ---
  };

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'],
      companyName: map['companyName'],
      customerName: map['customerName'],
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      date: map['date'],
      dueDate: map['dueDate'],
      status: map['status'],
      taxRate: map['taxRate'],
      notes: map['notes'] ?? '', // --- RETRIEVED FROM MAP ---
      items: items,
    );
  }
}