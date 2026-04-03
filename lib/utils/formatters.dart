import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String compactCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)} K';
    }
    return currency(amount);
  }

  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MM/yy').format(date);
  }

  /// Returns a formatted date-time string converted to IST (UTC+5:30).
  /// Example: "28 Mar 2026 • 03:45 PM IST"
  static String dateTimeIST(DateTime date) {
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    final datePart = DateFormat('dd MMM yyyy').format(ist);
    final timePart = DateFormat('hh:mm a').format(ist);
    return '$datePart • $timePart IST';
  }

  /// Short IST timestamp — "28 Mar • 03:45 PM"
  static String shortDateTimeIST(DateTime date) {
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM • hh:mm a').format(ist);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}