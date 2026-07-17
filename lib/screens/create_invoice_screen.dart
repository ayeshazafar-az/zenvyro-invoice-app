import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/invoice_provider.dart';
import '../models/invoice_model.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  // The form key allows us to validate the input fields
  final _formKey = GlobalKey<FormState>();

  // Controllers to grab the text typed by the user
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    // We must clean up controllers when the screen closes to prevent memory leaks
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveInvoice() {
    if (_formKey.currentState!.validate()) {

      final name = _nameController.text;
      final description = _descriptionController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Generate quick random IDs
      final String newInvoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
      final String newItemId = 'ITEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';

      // Format today's date
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Create the actual Invoice object
      final newInvoice = Invoice(
        id: newInvoiceId,
        companyName: 'My Company', // Hardcoded for now
        customerName: name,
        date: today,
        dueDate: today,
        status: 'Unpaid', // Default status
        taxRate: 0.0,
        // Creating a single item using the description and price from the form
        items: [
          InvoiceItem(
            id: newItemId,
            name: description,
            quantity: 1,
            unitPrice: price,
          )
        ],
      );

      // Send it to the Provider to save in SQLite and update the Dashboard
      Provider.of<InvoiceProvider>(context, listen: false).addInvoice(newInvoice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice Created Successfully!')),
      );

      // Slide back to the dashboard
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      // SingleChildScrollView prevents the keyboard from crushing the UI
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Client Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Client Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a client name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              const Text(
                'Invoice Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Item Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Item / Service Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveInvoice,
                  child: const Text('Save Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}