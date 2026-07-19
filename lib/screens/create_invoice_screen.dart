// lib/screens/create_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart'; // Added Notification Import

// --- HELPER CLASS ---
class ItemInputGroup {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountController = TextEditingController(text: '0');

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    discountController.dispose();
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? existingInvoice;
  final bool isDuplicate;

  const CreateInvoiceScreen({super.key, this.existingInvoice, this.isDuplicate = false});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();

  final _taxRateController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _invoicePrefix = 'INV-';

  final List<ItemInputGroup> _items = [];

  bool get isEditMode => widget.existingInvoice != null && !widget.isDuplicate;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final settings = await DBHelper.instance.getSettings();
    setState(() => _invoicePrefix = settings['invoicePrefix'] ?? 'INV-');

    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _customerNameController.text = inv.customerName;
      _customerEmailController.text = inv.customerEmail;
      _customerPhoneController.text = inv.customerPhone;
      _customerAddressController.text = inv.customerAddress;
      _taxRateController.text = inv.taxRate.toString();
      _notesController.text = inv.notes;

      if (!widget.isDuplicate) {
        _invoiceDate = DateTime.parse(inv.date);
        _dueDate = DateTime.parse(inv.dueDate);
      }

      for (var item in inv.items) {
        final group = ItemInputGroup();
        group.nameController.text = item.name;
        group.qtyController.text = item.quantity.toString();
        group.priceController.text = item.unitPrice.toString();
        group.discountController.text = item.discount.toString();
        _items.add(group);
      }
      setState(() {});
    } else {
      _taxRateController.text = (settings['defaultTaxRate'] ?? 0.0).toString();
      _items.add(ItemInputGroup());
    }
  }

  void _fillCustomerDetails(Map<String, dynamic> customer) {
    setState(() {
      _customerNameController.text = customer['name'];
      _customerEmailController.text = customer['email'] ?? '';
      _customerPhoneController.text = customer['phone'] ?? '';
      _customerAddressController.text = customer['address'] ?? '';
    });
  }

  void _addNewItemRow() => setState(() => _items.add(ItemInputGroup()));
  void _removeItemRow(int index) => setState(() { _items[index].dispose(); _items.removeAt(index); });

  double get _subtotal {
    double total = 0;
    for (var item in _items) {
      double qty = double.tryParse(item.qtyController.text) ?? 0;
      double price = double.tryParse(item.priceController.text) ?? 0;
      double discount = double.tryParse(item.discountController.text) ?? 0;
      total += (qty * price) - discount;
    }
    return total;
  }

  double get _taxAmount => _subtotal * ((double.tryParse(_taxRateController.text) ?? 0) / 100);
  double get _grandTotal => _subtotal + _taxAmount;

  void _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item.')));
        return;
      }

      final provider = Provider.of<InvoiceProvider>(context, listen: false);

      final isExisting = provider.customers.any((c) => c['name'] == _customerNameController.text);
      if (!isExisting && _customerNameController.text.isNotEmpty) {
        await provider.addCustomer(_customerNameController.text, _customerEmailController.text, _customerPhoneController.text, _customerAddressController.text);
      }

      final newInvoice = Invoice(
        id: isEditMode ? widget.existingInvoice!.id : '$_invoicePrefix${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        companyName: (await DBHelper.instance.getSettings())['companyName'] ?? 'My Company',
        customerName: _customerNameController.text,
        customerEmail: _customerEmailController.text,
        customerPhone: _customerPhoneController.text,
        customerAddress: _customerAddressController.text,
        date: DateFormat('yyyy-MM-dd').format(_invoiceDate),
        dueDate: DateFormat('yyyy-MM-dd').format(_dueDate),
        status: isEditMode ? widget.existingInvoice!.status : 'Unpaid',
        taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
        notes: _notesController.text,
        items: _items.map((g) => InvoiceItem(
          id: 'ITEM-${DateTime.now().microsecondsSinceEpoch}',
          name: g.nameController.text,
          quantity: int.tryParse(g.qtyController.text) ?? 1,
          unitPrice: double.tryParse(g.priceController.text) ?? 0.0,
          discount: double.tryParse(g.discountController.text) ?? 0.0,
        )).toList(),
      );

      provider.addInvoice(newInvoice);

      // --- Trigger Notification ---
      await NotificationService.scheduleNotification(
        newInvoice.id,
        newInvoice.customerName,
        DateTime.parse(newInvoice.dueDate),
      );

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Invoice' : 'Create Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<InvoiceProvider>(builder: (context, provider, _) {
                return DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(labelText: 'Select from History', border: OutlineInputBorder()),
                  items: provider.customers.map((c) => DropdownMenuItem(value: c, child: Text(c['name']))).toList(),
                  onChanged: (val) => val != null ? _fillCustomerDetails(val) : null,
                );
              }),
              const SizedBox(height: 16),
              TextFormField(controller: _customerNameController, decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _customerEmailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _customerPhoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _customerAddressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),

              const SizedBox(height: 24),
              const Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ..._items.asMap().entries.map((e) => Card(
                  child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: TextFormField(controller: e.value.nameController, decoration: const InputDecoration(labelText: 'Item Name *')),
                      ),
                      Consumer<InvoiceProvider>(builder: (context, provider, _) {
                        return PopupMenuButton<Map<String, dynamic>>(
                          icon: const Icon(Icons.list, color: Colors.blue),
                          onSelected: (prod) => setState(() {
                            e.value.nameController.text = prod['name'];
                            e.value.priceController.text = prod['price'].toString();
                          }),
                          itemBuilder: (context) => provider.products.map((prod) =>
                              PopupMenuItem(value: prod, child: Text('${prod['name']} (\$${prod['price']})'))
                          ).toList(),
                        );
                      }),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeItemRow(e.key))
                    ]),
                    Row(children: [
                      Expanded(child: TextFormField(controller: e.value.qtyController, decoration: const InputDecoration(labelText: 'Qty'), onChanged: (v) => setState(() {}))),
                      Expanded(child: TextFormField(controller: e.value.priceController, decoration: const InputDecoration(labelText: 'Price'), onChanged: (v) => setState(() {}))),
                      Expanded(child: TextFormField(controller: e.value.discountController, decoration: const InputDecoration(labelText: 'Discount'), onChanged: (v) => setState(() {}))),
                    ])
                  ]))
              )),
              TextButton.icon(onPressed: _addNewItemRow, icon: const Icon(Icons.add), label: const Text('Add Item')),

              const SizedBox(height: 20),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('\$${_subtotal.toStringAsFixed(2)}')],),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tax (%)'), SizedBox(width: 50, child: TextFormField(controller: _taxRateController, onChanged: (v) => setState(() {})))],),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total'), Text('\$${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))],),
              ]))),

              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveInvoice, child: const Text('Save Invoice'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    for (var i in _items) i.dispose();
    super.dispose();
  }
}