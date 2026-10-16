import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ThreadScope {
  passage,
  chapter,
  book,
  topic,
  subtopic;

  String get label {
    switch (this) {
      case ThreadScope.passage:
        return 'Passage';
      case ThreadScope.chapter:
        return 'Chapter';
      case ThreadScope.book:
        return 'Book';
      case ThreadScope.topic:
        return 'Topic';
      case ThreadScope.subtopic:
        return 'Subtopic';
    }
  }

  IconData get icon {
    switch (this) {
      case ThreadScope.passage:
        return LucideIcons.quote;
      case ThreadScope.chapter:
        return LucideIcons.bookmark;
      case ThreadScope.book:
        return LucideIcons.bookOpen;
      case ThreadScope.topic:
        return LucideIcons.hash;
      case ThreadScope.subtopic:
        return LucideIcons.cornerDownRight;
    }
  }

  static ThreadScope fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'passage':
        return ThreadScope.passage;
      case 'chapter':
        return ThreadScope.chapter;
      case 'topic':
        return ThreadScope.topic;
      case 'subtopic':
        return ThreadScope.subtopic;
      case 'book':
      default:
        return ThreadScope.book;
    }
  }
}
