import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/collection_model.dart';
import '../models/shop_model.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';

class PdfReportService {
  /// Generates and previews / shares the End of Day (EOD) PDF Collection Report
  static Future<void> generateAndShareEODReport({
    required DateTime date,
    required double totalAmount,
    required int shopsVisited,
    required double cashTotal,
    required double gpayTotal,
    required double bankTotal,
    required List<CollectionModel> collections,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMMM yyyy').format(date);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal800, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SHA COLLECTS',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.Text(
                        'Route Recovery & Daily Closing Summary',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DATE: $dateStr',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated at: ${DateFormat('hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Metrics Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfMetricItem('TOTAL RECOVERED', CurrencyFormatter.formatPdf(totalAmount), PdfColors.teal800),
                  _pdfMetricItem('SHOPS VISITED', '$shopsVisited', PdfColors.blueGrey800),
                  _pdfMetricItem('TRANSACTIONS', '${collections.length}', PdfColors.blueGrey800),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Mode Breakdown Box
            pw.Text(
              'Payment Mode Breakdown',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfModeCard('Cash Collections', CurrencyFormatter.formatPdf(cashTotal), PdfColors.green700),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _pdfModeCard('Google Pay (GPay)', CurrencyFormatter.formatPdf(gpayTotal), PdfColors.blue700),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _pdfModeCard('Company Account', CurrencyFormatter.formatPdf(bankTotal), PdfColors.purple700),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Itemized Transaction Table
            pw.Text(
              'Itemized Collection Log (${collections.length} entries)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Time', 'Shop Name', 'Mode', 'Amount Paid', 'Balance After'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              data: collections.map((c) {
                return [
                  DateFormat('hh:mm a').format(c.timestamp),
                  c.shopName,
                  c.paymentMode,
                  CurrencyFormatter.formatPdf(c.amountPaid),
                  CurrencyFormatter.formatPdf(c.balanceAfter),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 24),
            // Footer
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sha Collects • Route Recovery Automation', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Official Route Agent Closing Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final filename = 'Sha_Collects_EOD_${DateFormat('yyyyMMdd').format(date)}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// Generates and previews / shares a Shop Ledger Statement PDF
  static Future<void> generateAndShareShopLedger({
    required ShopModel shop,
    required List<CollectionModel> collections,
  }) async {
    final pdf = pw.Document();

    final totalPaid = collections.fold<double>(0.0, (acc, item) => acc + item.amountPaid);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal800, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SHA COLLECTS',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text('Account Statement / Payment Ledger', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Statement Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Route: ${shop.route}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Shop Details Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shop.shopName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      if (shop.ownerName.isNotEmpty)
                        pw.Text('Proprietor: ${shop.ownerName}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (shop.contactNumber.isNotEmpty)
                        pw.Text('Phone: ${shop.contactNumber}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Current Pending Due', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                      pw.Text(
                        CurrencyFormatter.formatPdf(shop.currentBalance),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                      ),
                      pw.Text('Total Collected: ${CurrencyFormatter.formatPdf(totalPaid)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green800)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Ledger Entries Table
            pw.Text('Payment History (${collections.length} entries)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Receipt ID', 'Date & Time', 'Payment Mode', 'Amount Paid', 'Balance After'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              data: collections.map((c) {
                final shortId = c.transactionId.length > 8 ? c.transactionId.substring(0, 8).toUpperCase() : c.transactionId;
                return [
                  '#$shortId',
                  DateFormat('dd MMM yyyy, hh:mm a').format(c.timestamp),
                  c.paymentMode,
                  CurrencyFormatter.formatPdf(c.amountPaid),
                  CurrencyFormatter.formatPdf(c.balanceAfter),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Thank you for your prompt business payments! • Sha Collects Route Recovery',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final sanitizedName = shop.shopName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'Statement_${sanitizedName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // Helper UI methods for PDF
  static pw.Widget _pdfMetricItem(String title, String value, PdfColor valueColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: valueColor)),
      ],
    );
  }

  static pw.Widget _pdfModeCard(String title, String amount, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(amount, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accentColor)),
        ],
      ),
    );
  }

  // ===================== TEXT SHARING (WHATSAPP / SMS) =====================

  /// Formats and shares daily summary as clear WhatsApp / text message
  static Future<void> shareEODTextSummary({
    required DateTime date,
    required double totalAmount,
    required int shopsVisited,
    required double cashTotal,
    required double gpayTotal,
    required double bankTotal,
    required List<CollectionModel> collections,
  }) async {
    final dateStr = DateFormat('dd MMM yyyy').format(date);

    final sb = StringBuffer();
    sb.writeln('📊 *SHA COLLECTS - DAILY EOD REPORT*');
    sb.writeln('📅 Date: $dateStr');
    sb.writeln('-----------------------------------');
    sb.writeln('💰 *Total Collected:* ${CurrencyFormatter.format(totalAmount)}');
    sb.writeln('🏪 *Shops Visited:* $shopsVisited');
    sb.writeln('🧾 *Transactions:* ${collections.length}');
    sb.writeln('');
    sb.writeln('💳 *Mode Breakdown:*');
    sb.writeln('• Cash: ${CurrencyFormatter.format(cashTotal)}');
    sb.writeln('• GPay: ${CurrencyFormatter.format(gpayTotal)}');
    sb.writeln('• Company Bank: ${CurrencyFormatter.format(bankTotal)}');
    sb.writeln('');
    if (collections.isNotEmpty) {
      sb.writeln('📝 *Recent Collections:*');
      for (final c in collections.take(5)) {
        sb.writeln('• ${c.shopName}: ${CurrencyFormatter.format(c.amountPaid)} (${c.paymentMode})');
      }
      if (collections.length > 5) {
        sb.writeln('... and ${collections.length - 5} more entries');
      }
    }
    sb.writeln('-----------------------------------');
    sb.writeln('Generated via Sha Collects App');

    await SharePlus.instance.share(
      ShareParams(
        text: sb.toString(),
        subject: 'Sha Collects EOD Report - $dateStr',
      ),
    );
  }

  /// Formats and shares payment receipt message for a shop
  static Future<void> sharePaymentReceipt({
    required CollectionModel collection,
    required ShopModel shop,
  }) async {
    final sb = StringBuffer();
    sb.writeln('🧾 *PAYMENT RECEIPT - SHA COLLECTS*');
    sb.writeln('🏪 Shop: ${collection.shopName}');
    sb.writeln('💵 Amount Received: ${CurrencyFormatter.format(collection.amountPaid)}');
    sb.writeln('💳 Mode: ${collection.paymentMode}');
    sb.writeln('🕒 Date & Time: ${DateFormatter.formatDateTime(collection.timestamp)}');
    sb.writeln('📉 Remaining Due: ${CurrencyFormatter.format(collection.balanceAfter)}');
    if (collection.note.isNotEmpty) {
      sb.writeln('📌 Note: ${collection.note}');
    }
    sb.writeln('');
    sb.writeln('Thank you for your payment!');

    await SharePlus.instance.share(
      ShareParams(
        text: sb.toString(),
        subject: 'Payment Receipt: ${collection.shopName}',
      ),
    );
  }
}
