/// Grading and result calculation helpers.
///
/// The default scale follows a common Pakistani board pattern (pass mark 40%).
library;

/// A single grade band.
class GradeBand {
  const GradeBand(this.label, this.minPercentage);

  final String label;
  final double minPercentage;
}

/// Default grade scale, evaluated from highest to lowest.
const List<GradeBand> defaultGradeScale = [
  GradeBand('A+', 80),
  GradeBand('A', 70),
  GradeBand('B', 60),
  GradeBand('C', 50),
  GradeBand('D', 40),
  GradeBand('F', 0),
];

/// A computed grade.
class GradeResult {
  const GradeResult({required this.label, required this.passed});

  final String label;
  final bool passed;
}

abstract final class ResultCalculator {
  /// Percentage of [obtained] out of [total] (0 when total is 0).
  static double percentage(num obtained, num total) {
    if (total <= 0) return 0;
    return (obtained / total) * 100;
  }

  /// Resolves the grade for a percentage using [scale].
  static GradeResult gradeFor(
    double percentage, {
    List<GradeBand> scale = defaultGradeScale,
    double passPercentage = 40,
  }) {
    for (final band in scale) {
      if (percentage >= band.minPercentage) {
        return GradeResult(
          label: band.label,
          passed: percentage >= passPercentage,
        );
      }
    }
    return const GradeResult(label: 'F', passed: false);
  }

  /// Combines percentage + grade into one call.
  static GradeResult evaluate(num obtained, num total) {
    final pct = percentage(obtained, total);
    return gradeFor(pct);
  }
}
