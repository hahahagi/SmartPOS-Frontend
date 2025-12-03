import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_history_model.dart';
import '../models/receipt_summary.dart';
import '../../utils/formatters.dart';

class PdfService {
  pw.Widget _buildDashedLine() {
    return pw.Container(
      height: 1,
      width: double.infinity,
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey,
            width: 1,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
    );
  }

  Future<Uint8List> generateReceipt(TransactionHistoryItem transaction) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SmartPOS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Jl. Gajah Tunggal No.16, RT.001/RW.002, Alam Jaya, Kec. Jatiuwung, Kota Tangerang, Banten 15133',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildDashedLine(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kode:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    transaction.code,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    formatDateTime(transaction.createdAt),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kasir:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    transaction.cashierName,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              _buildDashedLine(),
              pw.SizedBox(height: 5),
              ...transaction.items.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.productName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item.quantity} x ${formatCurrency(item.unitPrice)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          formatCurrency(item.totalPrice),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
              _buildDashedLine(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    formatCurrency(transaction.totalAmount),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Metode Bayar',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    transaction.paymentMethod.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Terima Kasih!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Simpan struk ini sebagai bukti pembayaran',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> printReceipt(TransactionHistoryItem transaction) async {
    final pdfBytes = await generateReceipt(transaction);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt-${transaction.code}',
    );
  }

  Future<File> saveReceipt(TransactionHistoryItem transaction) async {
    final pdfBytes = await generateReceipt(transaction);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_${transaction.code}.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  Future<Uint8List> generateReceiptFromSummary(
    ReceiptSummary receipt,
    String cashierName,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SmartPOS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Jl. Gajah Tunggal No.16, RT.001/RW.002, Alam Jaya, Kec. Jatiuwung, Kota Tangerang, Banten 15133',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildDashedLine(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kode:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    receipt.invoiceCode ?? receipt.localId,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    formatDateTime(receipt.createdAt),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kasir:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(cashierName, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              _buildDashedLine(),
              pw.SizedBox(height: 5),
              ...receipt.items.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.productName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item.quantity} x ${formatCurrency(item.price)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          formatCurrency(item.subtotal),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
              _buildDashedLine(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    formatCurrency(receipt.total),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (receipt.cashReceived != null) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tunai', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      formatCurrency(receipt.cashReceived!),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembali', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      formatCurrency(receipt.changeAmount ?? 0),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Metode Bayar',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    receipt.paymentMethod.name.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Terima Kasih!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Simpan struk ini sebagai bukti pembayaran',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> printReceiptFromSummary(
    ReceiptSummary receipt,
    String cashierName,
  ) async {
    final pdfBytes = await generateReceiptFromSummary(receipt, cashierName);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt-${receipt.invoiceCode ?? receipt.localId}',
    );
  }
}
