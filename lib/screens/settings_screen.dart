// lib/screens/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';
import '../services/invoice_provider.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // --- NEW CONTROLLERS ---
  final _taglineController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _websiteController = TextEditingController();

  final _prefixController = TextEditingController();
  final _taxRateController = TextEditingController();

  String _currency = '\$';
  String _logoPath = '';
  bool _isDarkMode = false;
  String _selectedTemplate = 'Simple';

  final List<String> _currencies = ['\$', '€', '£', 'Rs', '¥'];
  final List<String> _templates = ['Simple', 'Branded'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DBHelper.instance.getSettings();
    setState(() {
      _nameController.text = settings['companyName'] ?? '';
      _emailController.text = settings['companyEmail'] ?? '';
      _addressController.text = settings['companyAddress'] ?? '';
      _phoneController.text = settings['companyPhone'] ?? '';

      // --- LOAD NEW FIELDS ---
      _taglineController.text = settings['companyTagline'] ?? '';
      _taxNumberController.text = settings['companyTaxNumber'] ?? '';
      _websiteController.text = settings['companyWebsite'] ?? '';

      _prefixController.text = settings['invoicePrefix'] ?? 'INV-';
      _taxRateController.text = (settings['defaultTaxRate'] ?? 0.0).toString();

      _currency = _currencies.contains(settings['currency'])
          ? settings['currency']
          : '\$';

      _logoPath = settings['logoPath'] ?? '';
      _isDarkMode = (settings['isDarkMode'] ?? 0) == 1;
      _selectedTemplate = settings['selectedTemplate'] ?? 'Simple';
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<InvoiceProvider>(context, listen: false);

    await provider.toggleTheme(_isDarkMode);
    await provider.updateTemplate(_selectedTemplate);

    await DBHelper.instance.updateSettings(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),

      // --- SAVE NEW FIELDS ---
      tagline: _taglineController.text.trim(),
      taxNumber: _taxNumberController.text.trim(),
      website: _websiteController.text.trim(),

      logoPath: _logoPath,
      currency: _currency,
      defaultTaxRate: double.tryParse(_taxRateController.text) ?? 0.0,
      invoicePrefix: _prefixController.text.trim(),
      isDarkMode: _isDarkMode,
      selectedTemplate: _selectedTemplate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved Successfully!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleBackup() async {
    final success = await BackupService.backupDatabase();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Preparing backup file...' : 'Failed to create backup.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text('Warning: This will overwrite all your current invoices and settings with the selected backup file. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESTORE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await BackupService.restoreDatabase();
    if (mounted) {
      if (success) {
        await Provider.of<InvoiceProvider>(context, listen: false).fetchInvoices();
        await _loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database restored successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore canceled or failed.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final provider = Provider.of<InvoiceProvider>(context, listen: false);
      final invoices = provider.invoices;

      if (invoices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No invoices to export.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      String csvData = "Invoice ID,Customer Name,Date,Due Date,Status,Total Amount\n";
      for (var invoice in invoices) {
        csvData += '"${invoice.id}","${invoice.customerName}","${invoice.date}","${invoice.dueDate}","${invoice.status}","${invoice.grandTotal.toStringAsFixed(2)}"\n';
      }

      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/zenvyro_invoices_export.csv';
      final File file = File(filePath);
      await file.writeAsString(csvData);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], subject: 'Invoices Export CSV');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();

    // --- DISPOSE NEW CONTROLLERS ---
    _taglineController.dispose();
    _taxNumberController.dispose();
    _websiteController.dispose();

    _prefixController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (_logoPath.isNotEmpty && File(_logoPath).existsSync())
                          ? FileImage(File(_logoPath))
                          : null,
                      child: (_logoPath.isEmpty || !File(_logoPath).existsSync())
                          ? const Icon(Icons.business, size: 50, color: Colors.grey)
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Company Logo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: _isDarkMode,
                onChanged: (val) {
                  setState(() => _isDarkMode = val);
                  Provider.of<InvoiceProvider>(context, listen: false).toggleTheme(val);
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedTemplate,
                decoration: const InputDecoration(labelText: 'Invoice Template', border: OutlineInputBorder()),
                items: _templates.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedTemplate = val!),
              ),
              const SizedBox(height: 24),

              const Text('Company Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // ESSENTIAL FIELD: Company Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Company Name is required' : null,
              ),
              const SizedBox(height: 12),

              // --- NEW FIELDS ---
              TextField(controller: _taglineController, decoration: const InputDecoration(labelText: 'Tagline (e.g., Software Solutions)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _taxNumberController, decoration: const InputDecoration(labelText: 'Tax / NTN Number', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _websiteController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              // ------------------

              // ESSENTIAL FIELD: Company Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Company Email *', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Company Email is required';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ESSENTIAL FIELD: Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),

              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
              const SizedBox(height: 24),

              const Text('Invoice Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: _prefixController, decoration: const InputDecoration(labelText: 'Invoice Prefix', border: OutlineInputBorder())),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                      items: _currencies.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (val) => setState(() => _currency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Default Tax Rate (%)', border: OutlineInputBorder(), suffixText: '%'),
              ),
              const SizedBox(height: 32),

              const Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleBackup,
                      icon: const Icon(Icons.backup),
                      label: const Text('Backup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Invoices as CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}