import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Production-ready FemLyra invoice PDF generator.
///
/// Required pubspec packages:
///   pdf:
///   printing:
///
/// Recommended assets:
///   assets/icons/app_logo_final.png
///   assets/fonts/Poppins-Regular.ttf
///   assets/fonts/Poppins-SemiBold.ttf
///
/// Add these paths under `flutter.assets` in pubspec.yaml.
class FemLyraInvoicePdf {
  FemLyraInvoicePdf._();

  static const String defaultLogoAsset =
      'assets/icons/app_logo_final.png';
  static const String defaultRegularFontAsset =
      'assets/fonts/Poppins-Regular.ttf';
  static const String defaultBoldFontAsset =
      'assets/fonts/Poppins-SemiBold.ttf';

  // FemLyra branding palette.
  static final PdfColor _purple = PdfColor.fromHex('#7B23D5');
  static final PdfColor _purpleAccent = PdfColor.fromHex('#8D34E3');
  static final PdfColor _purpleDark = PdfColor.fromHex('#3D2866');
  static final PdfColor _pink = PdfColor.fromHex('#FF2C86');
  static final PdfColor _lavender = PdfColor.fromHex('#F7F1FF');
  static final PdfColor _lavenderStrong = PdfColor.fromHex('#EFE5FF');
  static final PdfColor _border = PdfColor.fromHex('#E6D8FA');
  static final PdfColor _muted = PdfColor.fromHex('#7B6A97');
  static final PdfColor _successBackground = PdfColor.fromHex('#EAF8F0');
  static final PdfColor _successText = PdfColor.fromHex('#17975D');
  static final PdfColor _pageBackground = PdfColor.fromHex('#FCFBFF');

  /// Creates a one-page A4 invoice matching the FemLyra branded design.
  static Future<Uint8List> generate({
    required FemLyraInvoiceData invoice,
    String logoAssetPath = defaultLogoAsset,
    String regularFontAssetPath = defaultRegularFontAsset,
    String boldFontAssetPath = defaultBoldFontAsset,
  }) async {
    final pw.Font regularFont = await _loadFont(
      regularFontAssetPath,
      fallback: pw.Font.helvetica(),
    );
    final pw.Font boldFont = await _loadFont(
      boldFontAssetPath,
      fallback: pw.Font.helveticaBold(),
    );
    final Uint8List? logoBytes = await _loadAssetBytes(logoAssetPath);

    final pw.Document document = pw.Document(
      title: 'FemLyra Invoice ${invoice.invoiceNumber}',
      author: invoice.brandName,
      subject: 'Consultation invoice',
      creator: 'FemLyra Flutter App',
      producer: 'FemLyra',
    );

    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (pw.Context context) {
          return pw.Container(
            color: _pageBackground,
            child: pw.Column(
              children: <pw.Widget>[
                _buildHeader(invoice, logoBytes),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(42, 34, 42, 14),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: <pw.Widget>[
                        _buildSummary(invoice),
                        pw.SizedBox(height: 14),
                        _buildInformationCards(invoice),
                        pw.SizedBox(height: 14),
                        _buildConsultationCard(invoice),
                        pw.SizedBox(height: 14),
                        _buildBillingSection(invoice),
                        pw.SizedBox(height: 14),
                        _buildTerms(invoice),
                        pw.Spacer(),
                        _buildFooter(invoice),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  /// Opens the native print / save dialog.
  static Future<bool> printInvoice({
    required FemLyraInvoiceData invoice,
  }) async {
    return Printing.layoutPdf(
      name: invoice.fileName,
      format: PdfPageFormat.a4,
      onLayout: (_) => generate(invoice: invoice),
    );
  }

  /// Opens the platform share sheet with the generated PDF attached.
  static Future<void> shareInvoice({
    required FemLyraInvoiceData invoice,
    String? subject,
    String? body,
  }) async {
    final Uint8List bytes = await generate(invoice: invoice);
    await Printing.sharePdf(
      bytes: bytes,
      filename: invoice.fileName,
      subject: subject ?? 'FemLyra invoice ${invoice.invoiceNumber}',
      body: body ?? 'Please find your FemLyra invoice attached.',
    );
  }

  static pw.Widget _buildHeader(
    FemLyraInvoiceData invoice,
    Uint8List? logoBytes,
  ) {
    return pw.Column(
      children: <pw.Widget>[
        pw.Container(
          height: 154,
          color: _purple,
          padding: const pw.EdgeInsets.fromLTRB(44, 38, 44, 30),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              if (logoBytes != null)
                pw.Container(
                  width: 52,
                  height: 52,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    fit: pw.BoxFit.contain,
                  ),
                )
              else
                pw.Container(
                  width: 52,
                  height: 52,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    'F',
                    style: pw.TextStyle(
                      color: _pink,
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      invoice.brandName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoice.brandTagline.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Invoice No. ${invoice.invoiceNumber}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9.5,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Date ${invoice.invoiceDate}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(height: 11, color: _purpleAccent),
      ],
    );
  }

  static pw.Widget _buildSummary(FemLyraInvoiceData invoice) {
    return _card(
      padding: pw.EdgeInsets.zero,
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            flex: 7,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  _sectionTitle('Invoice Summary'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    invoice.summaryText,
                    style: pw.TextStyle(
                      fontSize: 9.2,
                      color: _muted,
                      lineSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              color: _lavenderStrong,
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: <pw.Widget>[
                      pw.Text(
                        'Total Paid',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: _muted,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        invoice.formattedTotal,
                        style: pw.TextStyle(
                          fontSize: 15.5,
                          color: _pink,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 9),
                  _statusPill(invoice.paymentStatus),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInformationCards(FemLyraInvoiceData invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          child: _informationCard(
            title: 'Billed To',
            isPurple: true,
            rows: <_InvoiceField>[
              _InvoiceField('Name', invoice.customerName, bold: true),
              _InvoiceField('Email', invoice.customerEmail),
              _InvoiceField('Phone', invoice.customerPhone),
              _InvoiceField('Location', invoice.customerAddress),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _informationCard(
            title: 'Invoice Details',
            isPurple: true,
            rows: <_InvoiceField>[
              _InvoiceField('Invoice No.', invoice.invoiceNumber, bold: true),
              _InvoiceField('Issue Date', invoice.invoiceDate),
              _InvoiceField('Booking ID', invoice.bookingId),
              _InvoiceField(
                'Status',
                invoice.paymentStatus,
                customValue: _statusPill(invoice.paymentStatus),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConsultationCard(FemLyraInvoiceData invoice) {
    return _card(
      padding: pw.EdgeInsets.zero,
      child: pw.Column(
        children: <pw.Widget>[
          _cardHeader('Consultation Details'),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: pw.Column(
              children: <pw.Widget>[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: _fieldRow(
                        'Doctor',
                        invoice.doctorName,
                        valueBold: true,
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _fieldRow('Speciality', invoice.speciality),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: _fieldRow('Appointment', invoice.appointmentDate),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _fieldRow(
                        'Mode',
                        invoice.consultationMode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillingSection(FemLyraInvoiceData invoice) {
    final List<FemLyraInvoiceLineItem> items = invoice.items.isEmpty
        ? <FemLyraInvoiceLineItem>[
            FemLyraInvoiceLineItem(
              title: 'Doctor Consultation Fee',
              description:
                  'Professional services rendered by ${invoice.doctorName.replaceFirst('Dr. ', '')}',
              amount: invoice.totalAmount,
            ),
          ]
        : invoice.items;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        _sectionTitle('Billing Summary'),
        pw.SizedBox(height: 7),
        _card(
          padding: pw.EdgeInsets.zero,
          child: pw.Column(
            children: <pw.Widget>[
              pw.Container(
                color: _lavenderStrong,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: pw.Row(
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: _tableHeaderText('Description'),
                    ),
                    pw.SizedBox(
                      width: 84,
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: _tableHeaderText('Amount'),
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map(
                (FemLyraInvoiceLineItem item) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _border, width: 0.7),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: <pw.Widget>[
                            pw.Text(
                              item.title,
                              style: pw.TextStyle(
                                fontSize: 10.8,
                                color: _purpleDark,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (item.description.trim().isNotEmpty) ...<pw.Widget>[
                              pw.SizedBox(height: 3),
                              pw.Text(
                                item.description,
                                style: pw.TextStyle(
                                  fontSize: 8.8,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(
                        width: 84,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            invoice.formatAmount(item.amount),
                            style: pw.TextStyle(
                              fontSize: 10.8,
                              color: _purpleDark,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                color: PdfColor.fromHex('#FFF8FC'),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: pw.Row(
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: pw.Text(
                        'Total Amount Paid',
                        style: pw.TextStyle(
                          fontSize: 11.5,
                          color: _purpleDark,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      invoice.formattedTotal,
                      style: pw.TextStyle(
                        fontSize: 13.5,
                        color: _pink,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTerms(FemLyraInvoiceData invoice) {
    final List<String> terms = invoice.terms.isNotEmpty
        ? invoice.terms
        : <String>[
            'This is a computer-generated invoice and does not require a physical signature.',
            'Consultation fees are subject to the applicable cancellation and refund policy.',
            'For invoice support or payment queries, contact ${invoice.supportEmail}.',
          ];

    return _card(
      padding: pw.EdgeInsets.zero,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          _cardHeader('Terms & Notes'),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 11),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: terms
                  .map(
                    (String term) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: <pw.Widget>[
                          pw.Text(
                            '•',
                            style: pw.TextStyle(
                              color: _pink,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Text(
                              term,
                              style: pw.TextStyle(
                                fontSize: 8.4,
                                color: _muted,
                                lineSpacing: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(FemLyraInvoiceData invoice) {
    final String leftText = <String>[
      'This is a computer-generated invoice.',
      if (invoice.supportEmail.trim().isNotEmpty)
        'Support: ${invoice.supportEmail}',
      if (invoice.website.trim().isNotEmpty) invoice.website,
    ].join('  |  ');

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _border, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              leftText,
              style: pw.TextStyle(fontSize: 7.6, color: _muted),
            ),
          ),
          pw.Text(
            'Page 1 of 1',
            style: pw.TextStyle(fontSize: 7.6, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _informationCard({
    required String title,
    required List<_InvoiceField> rows,
    bool isPurple = true,
  }) {
    return _card(
      padding: pw.EdgeInsets.zero,
      child: pw.Column(
        children: <pw.Widget>[
          _cardHeader(title, isPurple: isPurple),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: pw.Column(
              children: rows
                  .map(
                    (_InvoiceField row) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 9),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: <pw.Widget>[
                          pw.SizedBox(
                            width: 72,
                            child: pw.Text(
                              row.label,
                              style: pw.TextStyle(
                                fontSize: 8.2,
                                color: _muted,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: row.customValue ??
                                pw.Text(
                                  row.value,
                                  maxLines: 2,
                                  style: pw.TextStyle(
                                    fontSize: 9.4,
                                    color: _purpleDark,
                                    fontWeight: row.bold
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _fieldRow(
    String label,
    String value, {
    bool valueBold = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(
          width: 70,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.2,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.4,
              color: _purpleDark,
              fontWeight:
                  valueBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _card({
    required pw.Widget child,
    pw.EdgeInsetsGeometry padding = const pw.EdgeInsets.all(12),
  }) {
    return pw.Container(
      padding: padding,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _border, width: 0.8),
        borderRadius: pw.BorderRadius.circular(11),
      ),
      child: child,
    );
  }

  static pw.Widget _cardHeader(String title, {bool isPurple = false}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: isPurple ? _purple : _lavenderStrong,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(10),
          topRight: pw.Radius.circular(10),
        ),
      ),
      child: pw.Text(
        isPurple ? title.toUpperCase() : title,
        style: pw.TextStyle(
          fontSize: isPurple ? 9.5 : 12,
          color: isPurple ? PdfColors.white : _purpleDark,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: isPurple ? 0.6 : 0.2,
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 12.5,
        color: _purpleDark,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _tableHeaderText(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8.2,
        color: _muted,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _statusPill(String status) {
    final bool paid = status.trim().toUpperCase() == 'PAID';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: pw.BoxDecoration(
        color: paid ? _successBackground : _lavender,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 8.4,
          color: paid ? _successText : _purple,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static Future<pw.Font> _loadFont(
    String assetPath, {
    required pw.Font fallback,
  }) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (_) {
      return fallback;
    }
  }

  static Future<Uint8List?> _loadAssetBytes(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

class FemLyraInvoiceData {
  const FemLyraInvoiceData({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.bookingId,
    required this.paymentStatus,
    required this.paymentId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    required this.doctorName,
    required this.speciality,
    required this.appointmentDate,
    required this.consultationMode,
    required this.totalAmount,
    this.items = const <FemLyraInvoiceLineItem>[],
    this.terms = const <String>[],
    this.brandName = 'FemLyra',
    this.brandTagline = "Women's Health Partner",
    this.summaryText =
        'Private online consultation invoice for completed booking.',
    this.supportEmail = 'support@femlyra.com',
    this.website = 'www.femlyra.com',
    this.currencySymbol = '₹',
  });

  final String invoiceNumber;
  final String invoiceDate;
  final String bookingId;
  final String paymentStatus;
  final String paymentId;

  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;

  final String doctorName;
  final String speciality;
  final String appointmentDate;
  final String consultationMode;

  final double totalAmount;
  final List<FemLyraInvoiceLineItem> items;
  final List<String> terms;

  final String brandName;
  final String brandTagline;
  final String summaryText;
  final String supportEmail;
  final String website;
  final String currencySymbol;

  String get formattedTotal => formatAmount(totalAmount);

  String get fileName {
    final String safeInvoiceNumber =
        invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'FemLyra_Invoice_$safeInvoiceNumber.pdf';
  }

  String formatAmount(double value) {
    return '$currencySymbol${value.toStringAsFixed(2)}';
  }
}

class FemLyraInvoiceLineItem {
  const FemLyraInvoiceLineItem({
    required this.title,
    required this.description,
    required this.amount,
  });

  final String title;
  final String description;
  final double amount;
}

class _InvoiceField {
  const _InvoiceField(
    this.label,
    this.value, {
    this.bold = false,
    this.customValue,
  });

  final String label;
  final String value;
  final bool bold;
  final pw.Widget? customValue;
}
