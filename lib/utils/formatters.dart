import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatCurrency(num value) => _currencyFormatter.format(value);

final _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

String formatDateTime(DateTime date) => _dateTimeFormatter.format(date);

final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

String formatDate(DateTime date) => _dateFormatter.format(date);
