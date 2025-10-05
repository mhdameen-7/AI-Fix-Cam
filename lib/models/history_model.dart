class HistoryItem {
  final String title;
  final String imageUrl;
  final String date;

  HistoryItem({required this.title, required this.imageUrl, required this.date});

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      date: json['date'] as String,
    );
  }
}
