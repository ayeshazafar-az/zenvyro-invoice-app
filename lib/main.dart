import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/invoice_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  // Required to ensure native background processes (like SQLite) initialize properly
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Creates the state hub and triggers the database fetch immediately
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
    return MaterialApp(
      title: 'Zenvyro Invoice Generator',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Automatically toggles between Dark and Light mode
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
      // This now points directly to your newly built Dashboard Screen
      home: const DashboardScreen(),
    );
  }
}