import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DBHelper.instance.getSettings();
    _nameController.text = settings['companyName'] ?? '';
    _addressController.text = settings['companyAddress'] ?? '';
    _phoneController.text = settings['companyPhone'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Company Name')),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await DBHelper.instance.updateSettings(_nameController.text, _addressController.text, _phoneController.text);
                Navigator.pop(context);
              },
              child: const Text('Save Profile'),
            )
          ],
        ),
      ),
    );
  }
}