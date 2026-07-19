// lib/screens/product_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/invoice_provider.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog')),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final prod = provider.products[index];
              return ListTile(
                title: Text(prod['name']),
                subtitle: Text('\$${prod['price']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => provider.deleteProduct(prod['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Provider.of<InvoiceProvider>(context, listen: false).addProduct(_nameController.text, double.tryParse(_priceController.text) ?? 0.0);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}