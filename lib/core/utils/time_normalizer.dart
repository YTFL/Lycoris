class TimeNormalizer {
  /// Converts combined hours and minutes to canonical total minutes
  static int fromHoursAndMinutes(int hours, int minutes) {
    final validHours = hours < 0 ? 0 : hours;
    final validMinutes = minutes < 0 ? 0 : minutes;
    return (validHours * 60) + validMinutes;
  }

  /// Converts decimal hours (e.g. 14.5) to canonical minutes (870)
  static int fromDecimalHours(double hours) {
    if (hours <= 0.0 || hours.isNaN || hours.isInfinite) return 0;
    return (hours * 60).round();
  }

  /// Converts raw float or integer minutes to canonical minutes
  static int fromRawMinutes(num minutes) {
    if (minutes <= 0 || minutes.isNaN || minutes.isInfinite) return 0;
    return minutes.round();
  }

  /// Formats total canonical minutes to standard human-readable string ("18h 45m", "45m", "10h", "0m")
  static String format(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Converts total canonical minutes back to decimal hours with 1 decimal precision
  static double toDecimalHours(int totalMinutes) {
    if (totalMinutes <= 0) return 0.0;
    return double.parse((totalMinutes / 60.0).toStringAsFixed(1));
  }
}
