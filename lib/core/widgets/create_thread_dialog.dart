import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';

class CreateThreadDialog extends StatefulWidget {
  final String bookId;
  final String communityId;
  final String communityName;
  final VoidCallback? onThreadCreated;
  final ThreadScope initialScope;
  final String? initialQuoteText;
  final String? initialHighlightId;
  final String? initialChapterTitle;

  const CreateThreadDialog({
    super.key,
    required this.bookId,
    required this.communityId,
    required this.communityName,
    this.onThreadCreated,
    this.initialScope = ThreadScope.book,
    this.initialQuoteText,
    this.initialHighlightId,
    this.initialChapterTitle,
  });

  @override
  State<CreateThreadDialog> createState() => _CreateThreadDialogState();
}

class _CreateThreadDialogState extends State<CreateThreadDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();
  late ThreadScope _selectedScope;
  String? _selectedParentTopicId;
  bool _isSubmitting = false;

  bool get _isFixedPassageScope =>
      widget.initialScope == ThreadScope.passage &&
      widget.initialQuoteText?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
    if (widget.initialChapterTitle?.isNotEmpty == true) {
      _chapterController.text = widget.initialChapterTitle!;
    } else {
      _chapterController.text = 'Chapter 1';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  void _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your thoughts or question.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final localData = context.read<LocalDataService>();
      final title = _titleController.text.trim();

      String highlightId;
      switch (_selectedScope) {
        case ThreadScope.passage:
          highlightId = widget.initialHighlightId ??
              'cfi-passage-${DateTime.now().millisecondsSinceEpoch}';
          break;
        case ThreadScope.chapter:
          highlightId = _chapterController.text.trim().isEmpty
              ? 'chapter-1'
              : _chapterController.text.trim();
          break;
        case ThreadScope.topic:
          highlightId = 'topic-${DateTime.now().millisecondsSinceEpoch}';
          break;
        case ThreadScope.subtopic:
          highlightId = 'subtopic-${DateTime.now().millisecondsSinceEpoch}';
          break;
        case ThreadScope.book:
          highlightId = 'book-overall';
          break;
      }

      await localData.createThread(
        highlightId: highlightId,
        bookId: widget.bookId,
        communityId: widget.communityId,
        title: title.isEmpty ? _selectedScope.label : title,
        content: content,
        scope: _selectedScope,
        chapterTitle: (_selectedScope == ThreadScope.book ||
                _selectedScope == ThreadScope.topic ||
                _selectedScope == ThreadScope.subtopic)
            ? null
            : _chapterController.text.trim(),
        quoteText: _selectedScope == ThreadScope.passage
            ? widget.initialQuoteText
            : null,
        parentTopicId: _selectedScope == ThreadScope.subtopic
            ? _selectedParentTopicId
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onThreadCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Discussion "${title.isEmpty ? _selectedScope.label : title}" published!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedScope.icon,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isFixedPassageScope
                                ? 'Discuss Passage'
                                : 'New Discussion',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.communityName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Passage quote excerpt preview if applicable
                if (_isFixedPassageScope) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.secondary,
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                    ),
                    child: Text(
                      widget.initialQuoteText!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Scope selector if not passage-fixed
                  Text(
                    'Topic Scope',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ThreadScope.book,
                      ThreadScope.topic,
                      ThreadScope.subtopic,
                      ThreadScope.chapter,
                    ].map((scope) {
                      final isSelected = _selectedScope == scope;
                      return ChoiceChip(
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          scope.icon,
                          size: 14,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        label: Text(
                          scope.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedScope = scope);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Subtopic parent topic picker
                  if (_selectedScope == ThreadScope.subtopic) ...[
                    Builder(
                      builder: (context) {
                        final topics = context
                            .read<LocalDataService>()
                            .getTopicsForBook(widget.bookId, communityId: widget.communityId);
                        if (_selectedParentTopicId == null && topics.isNotEmpty) {
                          _selectedParentTopicId = topics.first.id;
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedParentTopicId,
                          decoration: InputDecoration(
                            labelText: 'Parent Topic',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: topics.map((t) {
                            return DropdownMenuItem(value: t.id, child: Text(t.title));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedParentTopicId = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Chapter title field if Chapter scope
                  if (_selectedScope == ThreadScope.chapter) ...[
                    TextField(
                      controller: _chapterController,
                      decoration: InputDecoration(
                        labelText: 'Chapter Name or Number',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                // Title input
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: _isFixedPassageScope
                        ? 'Discussion Title (Optional)'
                        : 'Title (Optional)',
                    hintText: _isFixedPassageScope
                        ? 'e.g. Literary analysis of this passage'
                        : 'e.g. Character evolution in the opening',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Content input
                TextField(
                  controller: _contentController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Thoughts or Questions',
                    hintText: 'What did you notice? Ask or share your interpretation...',
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Post Discussion'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
