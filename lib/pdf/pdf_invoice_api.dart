// lib/pdf/pdf_invoice_api.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';
import '../database/db_helper.dart'; // Added to fetch settings

class PdfInvoiceApi {
  static Future<Uint8List> generate(Invoice invoice) async {
    // --- FETCH CURRENCY FROM SETTINGS ---
    final settings = await DBHelper.instance.getSettings();
    final String currency = settings['currency'] ?? '\$';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 30),
          _buildInvoiceDetails(invoice),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice, currency), // Passed currency
          pw.Divider(color: PdfColors.grey400),
          _buildTotal(invoice, currency),      // Passed currency
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildNotes(invoice.notes),
          ]
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              invoice.companyName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildLabelText('Address:', 'Islamabad'),
            _buildLabelText('Phone:', '0288282'),
          ],
        ),
        pw.Text(
          'INVOICE',
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey300,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.customerName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              if (invoice.customerEmail.isNotEmpty)
                _buildLabelText('Email:', invoice.customerEmail),
              if (invoice.customerPhone.isNotEmpty)
                _buildLabelText('Phone:', invoice.customerPhone),
              if (invoice.customerAddress.isNotEmpty)
                _buildLabelText('Address:', invoice.customerAddress),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildMetaData('Invoice #:', invoice.id),
              _buildMetaData('Date:', invoice.date),
              _buildMetaData('Due Date:', invoice.dueDate),
              _buildMetaData('Status:', invoice.status.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice, String currency) {
    final headers = ['Description', 'Qty', 'Unit Price', 'Discount', 'Total'];

    final data = invoice.items.map((item) {
      return [
        item.name,
        '${item.quantity}',
        '$currency${item.unitPrice.toStringAsFixed(2)}', // Using dynamic currency
        '$currency${item.discount.toStringAsFixed(2)}', // Using dynamic currency
        '$currency${item.total.toStringAsFixed(2)}',    // Using dynamic currency
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
    );
  }

  static pw.Widget _buildTotal(Invoice invoice, String currency) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Spacer(flex: 6),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                _buildSummaryRow('Subtotal', '$currency${invoice.subtotal.toStringAsFixed(2)}'), // Using dynamic currency
                _buildSummaryRow('Tax (${invoice.taxRate}%)', '$currency${invoice.taxAmount.toStringAsFixed(2)}'), // Using dynamic currency
                pw.Divider(color: PdfColors.grey400),
                _buildSummaryRow(
                  'Grand Total',
                  '$currency${invoice.grandTotal.toStringAsFixed(2)}', // Using dynamic currency
                  isGrandTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes / Payment Instructions:',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(notes, style: const pw.TextStyle(color: PdfColors.grey800)),
      ],
    );
  }

  static pw.Widget _buildLabelText(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.SizedBox(width: 6),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaData(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 100,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isGrandTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 16 : 12,
              fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isGrandTotal ? PdfColors.blue800 : PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 16 : 12,
              fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isGrandTotal ? PdfColors.blue800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}