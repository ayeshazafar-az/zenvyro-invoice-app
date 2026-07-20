// lib/pdf/pdf_generator.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../database/db_helper.dart';

class PdfGenerator {

  // Method used for Printing
  static Future<void> generateAndPrint(Invoice invoice, String templateType) async {
    final pdf = pw.Document();
    final settings = await DBHelper.instance.getSettings();

    // Load logo as pw.ImageProvider if path exists
    pw.ImageProvider? logoImage;
    final logoPath = settings['logoPath'] ?? '';
    if (logoPath.isNotEmpty && File(logoPath).existsSync()) {
      final bytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(bytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (templateType == 'Branded') {
            return _buildBrandedTemplate(invoice, settings, logoImage);
          } else {
            return _buildSimpleTemplate(invoice, settings, logoImage);
          }
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Method used for Downloading and Sharing
  static Future<Uint8List> generate(Invoice invoice, String templateType) async {
    final pdf = pw.Document();
    final settings = await DBHelper.instance.getSettings();

    // Load logo as pw.ImageProvider if path exists
    pw.ImageProvider? logoImage;
    final logoPath = settings['logoPath'] ?? '';
    if (logoPath.isNotEmpty && File(logoPath).existsSync()) {
      final bytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(bytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (templateType == 'Branded') {
            return _buildBrandedTemplate(invoice, settings, logoImage);
          } else {
            return _buildSimpleTemplate(invoice, settings, logoImage);
          }
        },
      ),
    );

    return await pdf.save();
  }

  // --- SIMPLE TEMPLATE ---
  static pw.Widget _buildSimpleTemplate(Invoice invoice, Map<String, dynamic> settings, pw.ImageProvider? logoImage) {
    final compEmail = settings['companyEmail'] ?? settings['email'] ?? '';
    final compPhone = settings['companyPhone'] ?? settings['phone'] ?? '';
    final compAddress = settings['companyAddress'] ?? settings['address'] ?? '';

    final compTagline = settings['companyTagline'] ?? '';
    final compTaxNumber = settings['companyTaxNumber'] ?? '';
    final compWebsite = settings['companyWebsite'] ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with optional Circular Logo & Dates
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(invoice.companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                if (compTagline.isNotEmpty)
                  pw.Text(compTagline, style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                pw.SizedBox(height: 5),
                pw.Text('Invoice ID: ${invoice.id}'),
                pw.Text('Invoice Date: ${invoice.date}'),
                pw.Text('Due Date: ${invoice.dueDate}'),
              ],
            ),
            if (logoImage != null)
              pw.Container(
                width: 55,
                height: 55,
                child: pw.ClipOval(
                  child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                ),
              ),
          ],
        ),

        pw.SizedBox(height: 10),
        pw.Divider(),

        // Company & Customer Full Details Section
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("From (Company):", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Name: ${invoice.companyName}'),
                  if (compEmail.isNotEmpty) pw.Text('Email: $compEmail'),
                  if (compPhone.isNotEmpty) pw.Text('Phone: $compPhone'),
                  if (compAddress.isNotEmpty) pw.Text('Address: $compAddress'),
                  if (compTaxNumber.isNotEmpty) pw.Text('Tax/NTN: $compTaxNumber'),
                  if (compWebsite.isNotEmpty) pw.Text('Web: $compWebsite'),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Bill To (Customer):", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Name: ${invoice.customerName}'),
                  if (invoice.customerEmail.isNotEmpty) pw.Text('Email: ${invoice.customerEmail}'),
                  if (invoice.customerPhone.isNotEmpty) pw.Text('Phone: ${invoice.customerPhone}'),
                  if (invoice.customerAddress.isNotEmpty) pw.Text('Address: ${invoice.customerAddress}'),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Items Table matching reference format (Description, Qty, Unit Price, Subtotal, Tax)
        pw.Table.fromTextArray(
          headers: ['Description', 'Qty', 'Unit Price', 'Subtotal', 'Tax'],
          data: invoice.items.map((item) {
            double lineSubtotal = item.total;
            double lineTax = lineSubtotal * (invoice.taxRate / 100);
            return [
              item.name,
              item.quantity.toString(),
              item.unitPrice.toStringAsFixed(2),
              lineSubtotal.toStringAsFixed(2),
              '${lineTax.toStringAsFixed(2)} (${invoice.taxRate.toStringAsFixed(invoice.taxRate.truncate() == invoice.taxRate ? 0 : 1)}%)',
            ];
          }).toList(),
        ),

        // --- NOTES SECTION ---
        if (invoice.notes.trim().isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text("Notes & Instructions:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(invoice.notes),
        ],

        pw.Spacer(),
        pw.Divider(),

        // QR Code & Totals Summary Block
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Scan to Pay", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                pw.SizedBox(height: 5),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: "https://paypal.me/yourusername/${invoice.grandTotal}",
                  width: 60,
                  height: 60,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text("SUBTOTAL: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 40),
                    pw.Text("${invoice.subtotal.toStringAsFixed(2)}"),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text("TAX: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 40),
                    pw.Text("${invoice.taxAmount.toStringAsFixed(2)}"),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text("TOTAL: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(width: 40),
                    pw.Text("${invoice.grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- BRANDED TEMPLATE ---
  static pw.Widget _buildBrandedTemplate(Invoice invoice, Map<String, dynamic> settings, pw.ImageProvider? logoImage) {
    final compEmail = settings['companyEmail'] ?? settings['email'] ?? '';
    final compPhone = settings['companyPhone'] ?? settings['phone'] ?? '';
    final compAddress = settings['companyAddress'] ?? settings['address'] ?? '';

    final compTagline = settings['companyTagline'] ?? '';
    final compTaxNumber = settings['companyTaxNumber'] ?? '';
    final compWebsite = settings['companyWebsite'] ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue, width: 2)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with Circular Logo, Title, and Dates
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 55,
                  height: 55,
                  child: pw.ClipOval(
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  ),
                )
              else
                pw.SizedBox(width: 55),
              pw.Column(
                children: [
                  pw.Text("OFFICIAL INVOICE",
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  pw.SizedBox(height: 2),
                  pw.Text('Date: ${invoice.date} | Due: ${invoice.dueDate}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(width: 55),
            ],
          ),
          if (compTagline.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(compTagline, style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
            ),
          ],
          pw.SizedBox(height: 20),

          // Company & Customer Full Details Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("From (Company):", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.Text('Name: ${invoice.companyName}'),
                    if (compEmail.isNotEmpty) pw.Text('Email: $compEmail'),
                    if (compPhone.isNotEmpty) pw.Text('Phone: $compPhone'),
                    if (compAddress.isNotEmpty) pw.Text('Address: $compAddress'),
                    if (compTaxNumber.isNotEmpty) pw.Text('Tax/NTN: $compTaxNumber'),
                    if (compWebsite.isNotEmpty) pw.Text('Web: $compWebsite'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("To (Customer):", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.Text('Name: ${invoice.customerName}'),
                    if (invoice.customerEmail.isNotEmpty) pw.Text('Email: ${invoice.customerEmail}'),
                    if (invoice.customerPhone.isNotEmpty) pw.Text('Phone: ${invoice.customerPhone}'),
                    if (invoice.customerAddress.isNotEmpty) pw.Text('Address: ${invoice.customerAddress}'),
                  ],
                ),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.blue),
          pw.SizedBox(height: 20),

          // Items Table
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['Description', 'Qty', 'Unit Price', 'Subtotal', 'Tax'],
            data: invoice.items.map((item) {
              double lineSubtotal = item.total;
              double lineTax = lineSubtotal * (invoice.taxRate / 100);
              return [
                item.name,
                item.quantity.toString(),
                item.unitPrice.toStringAsFixed(2),
                lineSubtotal.toStringAsFixed(2),
                '${lineTax.toStringAsFixed(2)} (${invoice.taxRate.toStringAsFixed(invoice.taxRate.truncate() == invoice.taxRate ? 0 : 1)}%)',
              ];
            }).toList(),
          ),

          // --- NOTES SECTION ---
          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text("Notes & Instructions:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.SizedBox(height: 5),
            pw.Text(invoice.notes),
          ],

          pw.Spacer(),

          // QR Code & Totals Summary Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Scan to Pay", style: pw.TextStyle(fontSize: 10, color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: "https://paypal.me/yourusername/${invoice.grandTotal}",
                    width: 60,
                    height: 60,
                    color: PdfColors.blue,
                  ),
                ],
              ),
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(left: 20),
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.blue.shade(0.1),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("SUBTOTAL"),
                          pw.Text("${invoice.subtotal.toStringAsFixed(2)}"),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("TAX"),
                          pw.Text("${invoice.taxAmount.toStringAsFixed(2)}"),
                        ],
                      ),
                      pw.Divider(color: PdfColors.blue),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text("${invoice.grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}