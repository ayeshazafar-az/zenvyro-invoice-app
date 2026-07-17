import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import '../models/invoice_model.dart';

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
  const CreateInvoiceScreen({super.key});

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

  // Date Variables
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7)); // Default due in 7 days

  final List<ItemInputGroup> _items = [];

  @override
  void initState() {
    super.initState();
    _addNewItemRow();
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
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _saveInvoice() {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item/service.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
        return;
      }

      final String newInvoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Convert DateTime objects to Strings for the database
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

      final newInvoice = Invoice(
        id: newInvoiceId,
        companyName: 'My Company',
        customerName: _customerNameController.text,
        // --- INJECTED NEW FIELDS HERE ---
        customerEmail: _customerEmailController.text,
        customerPhone: _customerPhoneController.text,
        customerAddress: _customerAddressController.text,
        // --------------------------------
        date: formattedDate,
        dueDate: formattedDueDate,
        status: 'Unpaid',
        taxRate: 0.0,
        items: finalItems,
      );

      Provider.of<InvoiceProvider>(context, listen: false).addInvoice(newInvoice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice Created Successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value!.isEmpty ? 'Enter customer name' : null,
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
                                decoration: const InputDecoration(labelText: 'Item Name', isDense: true),
                                validator: (value) => value!.isEmpty ? 'Required' : null,
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
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: itemGroup.priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Price (\$)', isDense: true),
                                validator: (value) => value!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: itemGroup.discountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Discount', isDense: true),
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
              const SizedBox(height: 40),

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
                  child: const Text('Save Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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