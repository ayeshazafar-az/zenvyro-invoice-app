// lib/screens/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _prefixController = TextEditingController();
  final _taxRateController = TextEditingController();

  // State Variables
  String _currency = '\$';
  String _logoPath = '';

  final List<String> _currencies = ['\$', '€', '£', 'Rs', '¥'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DBHelper.instance.getSettings();
    setState(() {
      _nameController.text = settings['companyName'] ?? '';
      _addressController.text = settings['companyAddress'] ?? '';
      _phoneController.text = settings['companyPhone'] ?? '';
      _prefixController.text = settings['invoicePrefix'] ?? 'INV-';
      _taxRateController.text = (settings['defaultTaxRate'] ?? 0.0).toString();

      // Ensure the saved currency exists in our list, otherwise default to $
      _currency = _currencies.contains(settings['currency'])
          ? settings['currency']
          : '\$';

      _logoPath = settings['logoPath'] ?? '';
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
    await DBHelper.instance.updateSettings(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      logoPath: _logoPath,
      currency: _currency,
      defaultTaxRate: double.tryParse(_taxRateController.text) ?? 0.0,
      invoicePrefix: _prefixController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved Successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- LOGO UPLOAD ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _logoPath.isNotEmpty ? FileImage(File(_logoPath)) : null,
                    child: _logoPath.isEmpty
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

            // --- COMPANY DETAILS ---
            const Text('Company Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // --- INVOICE PREFERENCES ---
            const Text('Invoice Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                        labelText: 'Invoice Prefix',
                        hintText: 'e.g. INV-',
                        border: OutlineInputBorder()
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                    items: _currencies.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _currency = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _taxRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Default Tax Rate (%)',
                  border: OutlineInputBorder(),
                  suffixText: '%'
              ),
            ),
            const SizedBox(height: 32),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}