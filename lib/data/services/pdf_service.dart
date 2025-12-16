import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/receipt_summary.dart';
import '../models/transaction_history_model.dart';
import '../../utils/formatters.dart';

class PdfService {
  /* ===========================================================
   * DASHED LINE
   * ===========================================================
   */
  pw.Widget _divider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
    );
  }

  /* ===========================================================
   * GENERATE PDF — RECEIPT SUMMARY (CHECKOUT)
   * ===========================================================
   */
  Future<Uint8List> generateReceiptFromSummary(
    ReceiptSummary r,
    String cashierName,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) {
            return _receiptLayout(
            code: r.invoiceCode ?? r.localId,
            createdAt: r.createdAt,
            cashierName: cashierName,
            paymentMethod: r.paymentMethod.toString().split('.').last,
            total: r.total,
            cashReceived: r.cashReceived,
            changeAmount: r.changeAmount,
            items: r.items.map((e) {
              return _Item(
                name: e.productName,
                qty: e.quantity,
                price: e.price,
                total: e.quantity * e.price,
              );
            }).toList(),
          );
        },
      ),
    );

    return doc.save();
  }

  /* ===========================================================
   * PRINT & SAVE — RECEIPT SUMMARY
   * ===========================================================
   */
  Future<void> printReceiptFromSummary(
    ReceiptSummary receipt,
    String cashierName,
  ) async {
    final bytes = await generateReceiptFromSummary(receipt, cashierName);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Receipt-${receipt.invoiceCode ?? receipt.localId}',
    );
  }

  Future<File> saveReceiptFromSummary(
    ReceiptSummary receipt,
    String cashierName,
  ) async {
    final bytes = await generateReceiptFromSummary(receipt, cashierName);
    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/receipt_${receipt.invoiceCode ?? receipt.localId}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /* ===========================================================
   * 🔥 PRINT FROM HISTORY (FIX DOSEN)
   * ===========================================================
   */
  Future<void> printReceiptFromHistory(TransactionHistoryItem t) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) {
          return _receiptLayout(
            code: t.code,
            createdAt: t.createdAt,
            cashierName: t.cashierName,
            paymentMethod: t.paymentMethod,
            total: t.totalAmount,
            cashReceived: t.isCash ? t.cashReceived : null,
            changeAmount: t.isCash ? t.changeAmount : null,
            items: t.items.map((e) {
              return _Item(
                name: e.productName,
                qty: e.quantity,
                price: e.unitPrice,
                total: e.totalPrice,
              );
            }).toList(),
          );
        },
      ),
    );

    final bytes = await doc.save();

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Receipt-${t.code}',
    );
  }

  /* ===========================================================
   * RECEIPT LAYOUT (DIPAKAI BERSAMA)
   * ===========================================================
   */
  pw.Widget _receiptLayout({
    required String code,
    required DateTime createdAt,
    required String cashierName,
    required String paymentMethod,
    required double total,
    double? cashReceived,
    double? changeAmount,
    required List<_Item> items,
  }) {
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
            'Jl. Gajah Tunggal No.16, Tangerang',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),

        _divider(),

        _row('Kode', code),
        _row('Tanggal', formatDateTime(createdAt)),
        _row('Kasir', cashierName),

        _divider(),

        ...items.map(
          (i) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                i.name,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${i.qty} x ${formatCurrency(i.price)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    formatCurrency(i.total),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
            ],
          ),
        ),

        _divider(),

        _rowBold('Total', formatCurrency(total)),

        if (cashReceived != null && changeAmount != null) ...[
          _row('Tunai', formatCurrency(cashReceived)),
          _row('Kembalian', formatCurrency(changeAmount)),
        ],

        _divider(),

        _row('Metode Bayar', paymentMethod.toUpperCase()),

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
      ],
    );
  }

  /* ===========================================================
   * SMALL HELPERS
   * ===========================================================
   */
  pw.Widget _row(String l, String v) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(v, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _rowBold(String l, String v) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(l,
            style:
                pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text(v,
            style:
                pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

/* ===========================================================
 * INTERNAL ITEM (TIDAK PAKAI MODEL BARU)
 * ===========================================================
 */
class _Item {
  final String name;
  final int qty;
  final double price;
  final double total;

  _Item({
    required this.name,
    required this.qty,
    required this.price,
    required this.total,
  });
}
