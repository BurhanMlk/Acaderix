import 'package:intl/intl.dart';

/// Deterministic date/time formatting helpers using the `en_US` locale data
/// that ships with `intl` by default.
abstract final class DateFormatters {
  static final DateFormat _date = DateFormat('dd MMM yyyy', 'en_US');
  static final DateFormat _dateTime = DateFormat(
    'dd MMM yyyy, hh:mm a',
    'en_US',
  );
  static final DateFormat _monthYear = DateFormat('MMM yyyy', 'en_US');
  static final DateFormat _time = DateFormat('hh:mm a', 'en_US');
  static final DateFormat _dayMonth = DateFormat('dd MMM', 'en_US');

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value);

  static String monthYear(DateTime? value) =>
      value == null ? '—' : _monthYear.format(value);

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value);

  static String dayMonth(DateTime? value) =>
      value == null ? '—' : _dayMonth.format(value);
}
