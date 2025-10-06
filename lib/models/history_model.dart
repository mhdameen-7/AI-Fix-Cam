class HistoryItem {
  final String title;
  final String imagePath; // This will be the path to the PERMANENTLY saved image
  final String date;

  HistoryItem({
    required this.title,
    required this.imagePath,
    required this.date,
  });

  /// Converts a HistoryItem object into a Map so we can save it as text.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imagePath': imagePath,
      'date': date,
    };
  }

  /// Creates a HistoryItem object from a Map that we load from storage.
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      title: json['title'] as String,
      imagePath: json['imagePath'] as String,
      date: json['date'] as String,
    );
  }
}

