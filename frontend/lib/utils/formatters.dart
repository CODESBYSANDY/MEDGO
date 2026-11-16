import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _dateFormat.format(dateTime);
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _timeFormat.format(dateTime);
  }

  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
