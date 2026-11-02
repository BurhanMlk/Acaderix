import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'package:academy_management/features/student/presentation/utils/student_pdf_generator.dart';

/// Tab presenting the student's academic examination results,
/// visual performance bar chart, and institutional PDF report card download.
class StudentResultsTab extends ConsumerStatefulWidget {
  const StudentResultsTab({super.key});

  @override
  ConsumerState<StudentResultsTab> createState() => _StudentResultsTabState();
}

class _StudentResultsTabState extends ConsumerState<StudentResultsTab> {
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProfileProvider);
    final branch = ref.watch(currentStudentBranchProvider);
    final results = ref.watch(currentStudentResultsProvider);
    final exams = ref.watch(currentAcademyExamsProvider);
    final courses = ref.watch(currentStudentCoursesProvider);
    final metrics = ref.watch(studentMetricsProvider);
    final theme = Theme.of(context);

    // Map exam IDs to names
    final examMap = {for (final e in exams) e.id: e.name};

    final totalExams = results.length;
    final passedExams = results.where((r) => r.passed).length;
    final avgScore = metrics.academicPercentage;

    final primaryStudent = student ??
        const Student(
          id: 'std_default',
          academyId: '',
          fullName: 'Student',
          rollNumber: '100001',
          academicSession: '2026-2027',
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Overall Academic Performance Hero Card
        GlassCard(
          padding: const EdgeInsets.all(18),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Academic Performance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Grade ${metrics.academicGrade}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI stats row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Overall Average',
                      '${avgScore.toStringAsFixed(1)}%',
                      const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      'Total Exams',
                      '$totalExams',
                      const Color(0xFFA855F7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      'Passed Rate',
                      totalExams > 0
                          ? '${((passedExams / totalExams) * 100).toStringAsFixed(0)}%'
                          : '100%',
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),

              // PDF Report Card Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(
                    _isGeneratingPdf
                        ? 'Generating Report Card...'
                        : 'Download Official Report Card (PDF)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _isGeneratingPdf
                      ? null
                      : () async {
                          setState(() => _isGeneratingPdf = true);
                          try {
                            await StudentPdfGenerator.printReportCard(
                              student: primaryStudent,
                              branch: branch,
                              results: results,
                              courses: courses,
                              metrics: metrics,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to generate PDF: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isGeneratingPdf = false);
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Bar Chart comparing exams
        if (results.isNotEmpty) ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      color: Color(0xFF818CF8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exam Scores (%)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: 100,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1E293B),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final r = results[groupIndex];
                            final title = examMap[r.examId] ?? 'Exam ${groupIndex + 1}';
                            return BarTooltipItem(
                              '$title\n${rod.toY.toStringAsFixed(1)}%',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 25,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < results.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'E${idx + 1}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withValues(alpha: 0.08),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(results.length, (index) {
                        final r = results[index];
                        final pct = r.totalMarks > 0
                            ? (r.obtainedMarks / r.totalMarks) * 100
                            : 0.0;
                        final isPass = r.passed;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: pct,
                              gradient: LinearGradient(
                                colors: isPass
                                    ? [
                                        const Color(0xFF6366F1),
                                        const Color(0xFF38BDF8),
                                      ]
                                    : [
                                        const Color(0xFFEF4444),
                                        const Color(0xFFF87171),
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. Detailed Results List
        Text(
          'Examination Breakdown (${results.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        if (results.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 44,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No Examination Results Yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your official marks and grade sheets will appear here once published by your instructors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...results.asMap().entries.map((entry) {
            final index = entry.key;
            final r = entry.value;
            final examName = examMap[r.examId] ?? 'Examination ${index + 1}';
            final pct = r.totalMarks > 0
                ? ((r.obtainedMarks / r.totalMarks) * 100).toStringAsFixed(1)
                : '0.0';
            final isPass = r.passed;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isPass
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        r.grade.isNotEmpty ? r.grade : (isPass ? 'P' : 'F'),
                        style: TextStyle(
                          color: isPass
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF87171),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          examName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Marks: ${r.obtainedMarks.toStringAsFixed(0)} / ${r.totalMarks.toStringAsFixed(0)} ($pct%)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPass
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPass
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isPass ? 'PASSED' : 'RETAKE',
                      style: TextStyle(
                        color: isPass
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
