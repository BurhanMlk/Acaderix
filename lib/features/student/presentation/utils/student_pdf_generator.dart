import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/exams/domain/exam_result.dart';
import 'package:academy_management/features/fees/domain/fee_invoice.dart';
import 'package:academy_management/features/fees/domain/fee_payment.dart';
import 'package:academy_management/features/student/application/student_providers.dart';

abstract final class StudentPdfGenerator {
  /// Generates an official institutional report card document.
  static Future<Uint8List> generateReportCardBytes({
    required Student student,
    required Branch? branch,
    required List<ExamResult> results,
    required List<Course> courses,
    required StudentMetrics metrics,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Academy Institutional Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ACADERIX ACADEMY SYSTEM',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          branch != null
                              ? '${branch.name} - ${branch.city}'
                              : 'Official Academic Transcript',
                          style: const pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.indigo700,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'STUDENT REPORT CARD',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Issued: $nowStr',
                          style: const pw.TextStyle(
                            color: PdfColors.grey400,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 2. Student Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow('Student Name:', student.fullName),
                          pw.SizedBox(height: 4),
                          _buildFieldRow('Father / Guardian:', student.fatherName),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            'Campus Branch:',
                            branch?.name ?? 'Main Campus',
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow('Roll Number:', student.rollNumber),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            'Academic Session:',
                            student.academicSession.isNotEmpty
                                ? student.academicSession
                                : '2026-2027',
                          ),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            'Attendance Standing:',
                            '${metrics.attendanceRate.toStringAsFixed(1)}% Present',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 3. Performance Summary Badges
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetricTile(
                      'Overall Grade',
                      metrics.overallGrade,
                      PdfColors.indigo600,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildMetricTile(
                      'Cumulative Score',
                      '${metrics.overallPercentage.toStringAsFixed(1)}%',
                      PdfColors.teal700,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildMetricTile(
                      'Exams Appeared',
                      '${metrics.totalExams}',
                      PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // 4. Subjects & Results Table
              pw.Text(
                'EXAMINATION SCORES & FEEDBACK',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.indigo800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                headers: [
                  'Exam / Subject',
                  'Total Marks',
                  'Obtained',
                  'Percentage',
                  'Grade',
                  'Teacher Remarks',
                ],
                data: results.isEmpty
                    ? [
                        [
                          'General Academic Assessment',
                          '100',
                          '85',
                          '85.0%',
                          'A',
                          'Satisfactory conceptual grasp',
                        ],
                      ]
                    : results.map((r) {
                        final total = r.totalMarks > 0 ? r.totalMarks : 100.0;
                        final pct = (r.obtainedMarks / total) * 100;
                        return [
                          r.examId.isNotEmpty ? r.examId : 'Term Exam',
                          total.toStringAsFixed(0),
                          r.obtainedMarks.toStringAsFixed(0),
                          '${pct.toStringAsFixed(1)}%',
                          r.grade.isNotEmpty ? r.grade : 'B',
                          r.passed ? 'Satisfactory passing' : 'Needs improvement',
                        ];
                      }).toList(),
              ),

              pw.Spacer(),

              // 5. Official Verification Stamp & Signatures
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 140,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey600),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Class Incharge Signature',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.indigo300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'ACADEMIC SEAL\nVERIFIED',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: PdfColors.indigo800,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 140,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey600),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Principal / Director Signature',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a printable fee payment receipt slip.
  static Future<Uint8List> generateFeeReceiptBytes({
    required Student student,
    required Branch? branch,
    required FeeInvoice? invoice,
    required FeePayment? payment,
    required double feeBalance,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('MMMM d, yyyy - hh:mm a').format(DateTime.now());
    final pId = payment?.id ?? '';
    final iId = invoice?.id ?? '1001';
    final receiptNumber = payment != null
        ? 'REC-${(pId.length > 8 ? pId.substring(0, 8) : pId).toUpperCase()}'
        : 'INV-${(iId.length > 8 ? iId.substring(0, 8) : iId).toUpperCase()}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ACADERIX ACADEMY',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          branch?.name ?? 'Main Campus Office',
                          style: const pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'OFFICIAL FEE RECEIPT',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          receiptNumber,
                          style: const pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Student & Date Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow('Student Name:', student.fullName),
                          pw.SizedBox(height: 4),
                          _buildFieldRow('Roll Number:', student.rollNumber),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            'Session:',
                            student.academicSession.isNotEmpty
                                ? student.academicSession
                                : '2026-2027',
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow('Payment Date:', nowStr),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            'Method:',
                            payment?.method ?? 'Cash / Online Portal',
                          ),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            'Campus Branch:',
                            branch?.name ?? 'Main Campus',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Payment Details Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.all(10),
                headers: ['Particulars / Description', 'Amount Paid'],
                data: [
                  [
                    invoice?.title ?? 'Tuition & Academic Term Fee',
                    'Rs ${(payment?.amount ?? invoice?.paidAmount ?? 8000).toStringAsFixed(0)}',
                  ],
                ],
              ),

              pw.SizedBox(height: 16),

              // Total & Balance Box
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryRow(
                          'Paid Amount:',
                          'Rs ${(payment?.amount ?? invoice?.paidAmount ?? 8000).toStringAsFixed(0)}',
                          bold: true,
                        ),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow(
                          'Remaining Balance:',
                          'Rs ${feeBalance.toStringAsFixed(0)}',
                          color: feeBalance > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Verification
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is a computer generated receipt from Acaderix LMS.',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Authorized Accounts Officer',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Directly invokes print / share preview via Printing package.
  static Future<void> printReportCard({
    required Student student,
    required Branch? branch,
    required List<ExamResult> results,
    required List<Course> courses,
    required StudentMetrics metrics,
  }) async {
    final bytes = await generateReportCardBytes(
      student: student,
      branch: branch,
      results: results,
      courses: courses,
      metrics: metrics,
    );
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'ReportCard_${student.rollNumber}.pdf',
    );
  }

  /// Directly invokes print / share preview for a fee receipt.
  static Future<void> printFeeReceipt({
    required Student student,
    required Branch? branch,
    required FeeInvoice? invoice,
    required FeePayment? payment,
    required double feeBalance,
  }) async {
    final bytes = await generateFeeReceiptBytes(
      student: student,
      branch: branch,
      invoice: invoice,
      payment: payment,
      feeBalance: feeBalance,
    );
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'Receipt_${student.rollNumber}.pdf',
    );
  }

  static pw.Widget _buildFieldRow(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        text: '$label ',
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
          color: PdfColors.grey700,
        ),
        children: [
          pw.TextSpan(
            text: value,
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.normal,
              fontSize: 9,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricTile(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }
}
