/// Presentation only: API values and form input retain their original types.
String formatVnd(num amount) => amount
    .toStringAsFixed(0)
    .replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

String formatVietnameseDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
