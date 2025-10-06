import 'dart:convert';

class HistoryItem {
  final String title;
  final String imagePath;
  final String date;
  final String problemKey; // NEW: We add this to link back to the solution

  HistoryItem({
    required this.title,
    required this.imagePath,
    required this.date,
    required this.problemKey, // NEW
  });

  // Converts a HistoryItem object into a format that can be stored (a Map).
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imagePath': imagePath,
      'date': date,
      'problemKey': problemKey, // NEW
    };
  }

  // Creates a HistoryItem object from a Map (retrieved from storage).
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      title: json['title'] as String,
      imagePath: json['imagePath'] as String,
      date: json['date'] as String,
      problemKey: json['problemKey'] as String? ?? '', // NEW (handle old items safely)
    );
  }
}

