// lib/pdf/pdf_invoice_api.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';

class PdfInvoiceApi {
  static Future<Uint8List> generate(Invoice invoice) async {
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
          _buildItemsTable(invoice),
          pw.Divider(color: PdfColors.grey400),
          _buildTotal(invoice),
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
        // Company Info
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
            // You can replace these with actual company settings variables later
            _buildLabelText('Address:', 'Islamabad'),
            _buildLabelText('Phone:', '0288282'),
          ],
        ),
        // INVOICE Title
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
        // Customer Info
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
        // Invoice Meta Data
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

  static pw.Widget _buildItemsTable(Invoice invoice) {
    final headers = ['Description', 'Qty', 'Unit Price', 'Discount', 'Total'];

    final data = invoice.items.map((item) {
      return [
        item.name,
        '${item.quantity}',
        '\$${item.unitPrice.toStringAsFixed(2)}',
        '\$${item.discount.toStringAsFixed(2)}',
        '\$${item.total.toStringAsFixed(2)}',
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

  static pw.Widget _buildTotal(Invoice invoice) {
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
                _buildSummaryRow('Subtotal', '\$${invoice.subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('Tax (${invoice.taxRate}%)', '\$${invoice.taxAmount.toStringAsFixed(2)}'),
                pw.Divider(color: PdfColors.grey400),
                _buildSummaryRow(
                  'Grand Total',
                  '\$${invoice.grandTotal.toStringAsFixed(2)}',
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

  // --- HELPER WIDGETS ---

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