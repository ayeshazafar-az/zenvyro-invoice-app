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

  // Automatically calculate the total for this specific row
  double get total => (quantity * unitPrice) - discount;

  // Convert to Map for SQLite
  Map<String, dynamic> toMap(String invoiceId) => {
    'id': id,
    'invoiceId': invoiceId,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
  };

  // Create from Map (when fetching from SQLite)
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
  final String date;
  final String dueDate;
  final String status;
  final double taxRate;
  List<InvoiceItem> items; // Can be updated when fetching from DB

  Invoice({
    required this.id,
    required this.companyName,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.taxRate,
    required this.items,
  });

  // Math logic for the entire invoice
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get grandTotal => subtotal + taxAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'companyName': companyName,
    'customerName': customerName,
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
      date: map['date'],
      dueDate: map['dueDate'],
      status: map['status'],
      taxRate: map['taxRate'],
      items: items,
    );
  }
}