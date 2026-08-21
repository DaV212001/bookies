class Highlight {
  final String id;
  final String bookId;
  final String userId;
  final String text; // The highlighted text
  final String cfi;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.text,
    required this.cfi,
    required this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      cfi: json['cfi'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'text': text,
      'cfi': cfi,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
