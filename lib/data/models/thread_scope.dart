import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ThreadScope {
  passage,
  chapter,
  book;

  String get label {
    switch (this) {
      case ThreadScope.passage:
        return 'Passage';
      case ThreadScope.chapter:
        return 'Chapter';
      case ThreadScope.book:
        return 'Book';
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
    }
  }

  static ThreadScope fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'passage':
        return ThreadScope.passage;
      case 'chapter':
        return ThreadScope.chapter;
      case 'book':
      default:
        return ThreadScope.book;
    }
  }
}
