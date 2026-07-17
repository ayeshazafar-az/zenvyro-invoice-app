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
  // --- NEW FIELDS ---
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  // ------------------
  final String date;
  final String dueDate;
  final String status;
  final double taxRate;
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
    required this.items,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get grandTotal => subtotal + taxAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'companyName': companyName,
    'customerName': customerName,
    'customerEmail': customerEmail,     // Added to map
    'customerPhone': customerPhone,     // Added to map
    'customerAddress': customerAddress, // Added to map
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'taxRate': taxRate,
  };

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'],
      companyName: map['companyName'],
      customerName: map['customerName'],
      // We use ?? '' as a safety net in case a field is ever null
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      date: map['date'],
      dueDate: map['dueDate'],
      status: map['status'],
      taxRate: map['taxRate'],
      items: items,
    );
  }
}