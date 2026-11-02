import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:academy_management/core/domain/attendance_calculator.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/attendance/domain/attendance_record.dart';
import 'package:academy_management/features/branches/domain/branch.dart';

/// PDF document builder for institutional attendance registers and muster rolls.
abstract final class AttendancePdfGenerator {
  /// Generates the raw PDF bytes for an institutional course/branch attendance register.
  static Future<Uint8List> generateAttendanceRegisterBytes({
    required String academyName,
    required Branch? branch,
    required Course? course,
    required String teacherName,
    required DateTime date,
    required List<Student> students,
    required Map<String, AttendanceRecord> recordMap,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(date);
    final printDateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Calculate metrics
    int present = 0;
    int late = 0;
    int absent = 0;
    int leave = 0;

    for (final s in students) {
      final rec = recordMap[s.id];
      if (rec != null) {
        switch (rec.status) {
          case AttendanceStatus.present:
            present++;
          case AttendanceStatus.late:
            late++;
          case AttendanceStatus.absent:
            absent++;
          case AttendanceStatus.leave:
            leave++;
        }
      }
    }

    final total = students.length;
    final rate = AttendanceCalculator.percentage(
      presentDays: present + late,
      totalDays: total == 0 ? 1 : total,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey900,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        academyName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        branch != null
                            ? '${branch.name} - ${branch.city}'
                            : 'Campus Attendance Register',
                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal700,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'DAILY MUSTER ROLL',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: $printDateStr',
                        style: const pw.TextStyle(
                          color: PdfColors.grey400,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 2. Class & Schedule Metadata Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaRow('Date of Record:', dateStr),
                      pw.SizedBox(height: 4),
                      _metaRow('Course / Batch:', course?.name ?? 'All Branch Students'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaRow('Staff / Instructor:', teacherName.isNotEmpty ? teacherName : 'Institutional Staff'),
                      pw.SizedBox(height: 4),
                      _metaRow('Enrolled Capacity:', '$total students'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 3. Quantitative Summary Chips
            pw.Row(
              children: [
                _summaryChip('PRESENT', present, PdfColors.green700, PdfColors.green50),
                pw.SizedBox(width: 8),
                _summaryChip('LATE', late, PdfColors.amber800, PdfColors.amber50),
                pw.SizedBox(width: 8),
                _summaryChip('ABSENT', absent, PdfColors.red700, PdfColors.red50),
                pw.SizedBox(width: 8),
                _summaryChip('LEAVE', leave, PdfColors.purple700, PdfColors.purple50),
                pw.SizedBox(width: 8),
                _summaryChip('RATE', '${rate.toStringAsFixed(0)}%', PdfColors.blue800, PdfColors.blue50),
              ],
            ),
            pw.SizedBox(height: 16),

            // 4. Student Attendance Table
            pw.Text(
              'STUDENT ATTENDANCE LEDGER',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(36),
                1: const pw.FixedColumnWidth(64),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FixedColumnWidth(74),
                4: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeader('#'),
                    _tableHeader('Roll No.'),
                    _tableHeader('Student Name'),
                    _tableHeader('Status'),
                    _tableHeader('Notes / Sign'),
                  ],
                ),
                ...students.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  final rec = recordMap[s.id];
                  final statusText = rec != null ? rec.status.name.toUpperCase() : 'UNMARKED';
                  final statusColor = rec != null
                      ? switch (rec.status) {
                          AttendanceStatus.present => PdfColors.green800,
                          AttendanceStatus.late => PdfColors.amber800,
                          AttendanceStatus.absent => PdfColors.red800,
                          AttendanceStatus.leave => PdfColors.purple800,
                        }
                      : PdfColors.grey600;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _tableCell('$idx', align: pw.TextAlign.center),
                      _tableCell('#${s.rollNumber}', isBold: true),
                      _tableCell(s.fullName),
                      _tableCell(statusText, color: statusColor, isBold: true, align: pw.TextAlign.center),
                      _tableCell('', align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 30),

            // 5. Verification Signatures Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Teacher Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Admin / Principal Stamp', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Prints or presents a system share sheet for the generated attendance register.
  static Future<void> printOrShareAttendanceRegister({
    required String academyName,
    required Branch? branch,
    required Course? course,
    required String teacherName,
    required DateTime date,
    required List<Student> students,
    required Map<String, AttendanceRecord> recordMap,
  }) async {
    final pdfBytes = await generateAttendanceRegisterBytes(
      academyName: academyName,
      branch: branch,
      course: course,
      teacherName: teacherName,
      date: date,
      students: students,
      recordMap: recordMap,
    );

    final dateSlug = DateFormat('yyyy-MM-dd').format(date);
    final courseSlug = course?.name.replaceAll(RegExp(r'\s+'), '_') ?? 'Branch';
    final fileName = 'Attendance_${courseSlug}_$dateSlug.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _summaryChip(String label, dynamic count, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.6),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              '$count',
              style: pw.TextStyle(color: textColor, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              label,
              style: pw.TextStyle(color: textColor, fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isBold = false,
    PdfColor color = PdfColors.black,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
