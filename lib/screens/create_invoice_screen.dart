// lib/screens/create_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart'; // Added to fetch settings

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

  // Customer Info Controllers
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();

  // Tax & Notes Controllers
  final _taxRateController = TextEditingController(text: '0');
  final _notesController = TextEditingController(); // NEW: Notes Controller

  // Date Variables
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  // Settings Variable
  String _invoicePrefix = 'INV-';

  final List<ItemInputGroup> _items = [];

  bool get isEditMode => widget.existingInvoice != null && !widget.isDuplicate;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.existingInvoice != null) {
      // --- POPULATE FOR EDIT OR DUPLICATE ---
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
      // --- NEW INVOICE: LOAD DEFAULT SETTINGS ---
      final settings = await DBHelper.instance.getSettings();
      setState(() {
        _taxRateController.text = (settings['defaultTaxRate'] ?? 0.0).toString();
        _invoicePrefix = settings['invoicePrefix'] ?? 'INV-';
        _items.add(ItemInputGroup());
      });
    }
  }

  void _addNewItemRow() {
    setState(() {
      _items.add(ItemInputGroup());
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  // --- LIVE CALCULATIONS ---
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

  double get _taxAmount {
    double taxRate = double.tryParse(_taxRateController.text) ?? 0;
    return _subtotal * (taxRate / 100);
  }

  double get _grandTotal {
    return _subtotal + _taxAmount;
  }

  // --- DATE PICKER LOGIC ---
  Future<void> _selectInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _saveInvoice() async {
    // Validates all required fields
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
        return;
      }

      // Keep ID if editing, otherwise generate new ID with custom prefix
      final String finalInvoiceId = isEditMode
          ? widget.existingInvoice!.id
          : '$_invoicePrefix${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final String formattedDate = DateFormat('yyyy-MM-dd').format(_invoiceDate);
      final String formattedDueDate = DateFormat('yyyy-MM-dd').format(_dueDate);

      List<InvoiceItem> finalItems = [];
      for (var i = 0; i < _items.length; i++) {
        final group = _items[i];
        finalItems.add(
            InvoiceItem(
              id: 'ITEM-${DateTime.now().millisecondsSinceEpoch}-$i',
              name: group.nameController.text,
              quantity: int.tryParse(group.qtyController.text) ?? 1,
              unitPrice: double.tryParse(group.priceController.text) ?? 0.0,
              discount: double.tryParse(group.discountController.text) ?? 0.0,
            )
        );
      }

      // Fetch settings to inject dynamic company name
      final settings = await DBHelper.instance.getSettings();

      final newInvoice = Invoice(
        id: finalInvoiceId,
        companyName: settings['companyName'] ?? 'My Company',
        customerName: _customerNameController.text,
        customerEmail: _customerEmailController.text,
        customerPhone: _customerPhoneController.text,
        customerAddress: _customerAddressController.text,
        date: formattedDate,
        dueDate: formattedDueDate,
        status: isEditMode ? widget.existingInvoice!.status : 'Unpaid',
        taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
        notes: _notesController.text, // --- Saving Notes ---
        items: finalItems,
      );

      Provider.of<InvoiceProvider>(context, listen: false).addInvoice(newInvoice);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? 'Invoice Updated Successfully!' : 'Invoice Created Successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Invoice' : widget.isDuplicate ? 'Duplicate Invoice' : 'Create New Invoice', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DATES ---
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectInvoiceDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Invoice Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_invoiceDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectDueDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.event, size: 20),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- CUSTOMER DETAILS ---
              const Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Customer name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerAddressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Billing Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // --- DYNAMIC ITEMS LIST ---
              const Text('Products / Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),

              ..._items.asMap().entries.map((entry) {
                int index = entry.key;
                ItemInputGroup itemGroup = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: itemGroup.nameController,
                                decoration: const InputDecoration(labelText: 'Item Name *', isDense: true),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItemRow(index),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: itemGroup.qtyController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Qty *', isDense: true),
                                onChanged: (value) => setState(() {}), // Triggers live calculation
                                validator: (value) => value == null || int.tryParse(value) == null || int.parse(value) <= 0 ? 'Invalid' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: itemGroup.priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Price *', isDense: true),
                                onChanged: (value) => setState(() {}),
                                validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: itemGroup.discountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Discount', isDense: true),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              TextButton.icon(
                onPressed: _addNewItemRow,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Another Item'),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),

              // --- NOTES SECTION ---
              const Text('Notes & Payment Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Thank you for your business! Please make checks payable to...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // --- SUMMARY & TAX ---
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax Rate (%):', style: TextStyle(fontSize: 16)),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _taxRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax Amount:', style: TextStyle(fontSize: 16)),
                          Text('\$${_taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveInvoice,
                  child: Text(isEditMode ? 'Update Invoice' : 'Save Invoice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}