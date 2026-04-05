const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Returns e.g. "Jan 5, 2024"
String formatDate(DateTime? dt) {
  if (dt == null) return '';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// Returns e.g. "2024-01-05"
String formatDateISO(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
