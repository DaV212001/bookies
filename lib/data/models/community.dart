class Community {
  final String id;
  final String name;
  final String description;
  final String bookId; // The reference book for this community
  final int memberCount;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.bookId,
    required this.memberCount,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      bookId: json['bookId'] as String,
      memberCount: json['memberCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bookId': bookId,
      'memberCount': memberCount,
    };
  }
}
