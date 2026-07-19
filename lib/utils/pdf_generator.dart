// lib/utils/pdf_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';

class PdfGenerator {

  // Method used for Printing
  static Future<void> generateAndPrint(Invoice invoice, String templateType) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (templateType == 'Branded') {
            return _buildBrandedTemplate(invoice);
          } else {
            return _buildSimpleTemplate(invoice);
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (templateType == 'Branded') {
            return _buildBrandedTemplate(invoice);
          } else {
            return _buildSimpleTemplate(invoice);
          }
        },
      ),
    );

    return await pdf.save();
  }

  // --- SIMPLE TEMPLATE ---
  static pw.Widget _buildSimpleTemplate(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(invoice.companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text('Invoice ID: ${invoice.id}'),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.Text("Bill To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(invoice.customerName),
        pw.Text(invoice.customerAddress),
        pw.SizedBox(height: 20),

        // Items Table
        pw.Table.fromTextArray(
          headers: ['Item', 'Qty', 'Unit Price', 'Total'],
          data: invoice.items.map((item) => [
            item.name,
            item.quantity.toString(),
            item.unitPrice.toStringAsFixed(2),
            (item.quantity * item.unitPrice).toStringAsFixed(2)
          ]).toList(),
        ),

        pw.Spacer(),
        pw.Divider(),

        // --- ADDED QR CODE HERE ---
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
                  ]
              ),
              pw.Text("Grand Total: ${invoice.grandTotal.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ]
        ),
      ],
    );
  }

  // --- BRANDED TEMPLATE ---
  static pw.Widget _buildBrandedTemplate(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue, width: 2)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text("OFFICIAL INVOICE",
                style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("From: ${invoice.companyName}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("To: ${invoice.customerName}"),
              ]
          ),
          pw.Divider(color: PdfColors.blue),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['Item', 'Qty', 'Price'],
            data: invoice.items.map((i) => [i.name, i.quantity.toString(), i.unitPrice.toString()]).toList(),
          ),

          pw.Spacer(),

          // --- ADDED QR CODE HERE ---
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
                    ]
                ),
                pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(left: 20),
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.blue.shade(0.1),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("TOTAL AMOUNT"),
                          pw.Text("${invoice.grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ]
                    ),
                  ),
                ),
              ]
          ),
        ],
      ),
    );
  }
}