// lib/utils/invoice_templates.dart

import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';

abstract class InvoiceTemplate {
  pw.Widget build(Invoice invoice);
}

class SimpleTemplate implements InvoiceTemplate {
  @override
  pw.Widget build(Invoice invoice) => pw.Center(child: pw.Text("Simple Layout: ${invoice.customerName}"));
}

class BrandedTemplate implements InvoiceTemplate {
  @override
  pw.Widget build(Invoice invoice) => pw.Container(
    decoration: pw.BoxDecoration(border: pw.Border.all()),
    child: pw.Text("Branded Layout for ${invoice.companyName}"),
  );
}