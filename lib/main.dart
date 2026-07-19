// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/invoice_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceProvider()..fetchInvoices()),
      ],
      child: const InvoiceGeneratorApp(),
    ),
  );
}

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the provider to get the theme preference
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Zenvyro Invoice Generator',
          debugShowCheckedModeBanner: false,

          // Switch between Light and Dark based on the database value
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}