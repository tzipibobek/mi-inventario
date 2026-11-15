DateTime startOfWeek(DateTime date) {
  // La semana empieza el lunes. DateTime permite cruzar meses y años.
  return DateTime(date.year, date.month, date.day - date.weekday + 1);
}

DateTime nextWeek(DateTime weekStart) {
  return DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
}

String shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String dateAndTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${shortDate(date)} · $hour:$minute';
}
