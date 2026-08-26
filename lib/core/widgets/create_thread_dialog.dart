import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final TextEditingController _chapterController = TextEditingController(
    text: 'Chapter 1: The Gathering',
  );
  final TextEditingController _quoteController = TextEditingController();
  late ThreadScope _selectedScope;
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
    _quoteController.text = widget.initialQuoteText ?? '';
    if (widget.initialChapterTitle?.isNotEmpty == true) {
      _chapterController.text = widget.initialChapterTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _chapterController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  void _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter discussion content'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final localData = context.read<LocalDataService>();
    final highlightId = _selectedScope == ThreadScope.passage
        ? (widget.initialHighlightId ?? 'cfi-passage-custom')
        : _selectedScope == ThreadScope.chapter
        ? _chapterController.text.trim()
        : 'book-overall';

    await localData.createThread(
      highlightId: highlightId,
      bookId: widget.bookId,
      communityId: widget.communityId,
      title: title.isEmpty ? _selectedScope.label : title,
      content: content,
      scope: _selectedScope,
      chapterTitle: _selectedScope == ThreadScope.book
          ? null
          : _chapterController.text.trim(),
      quoteText: _selectedScope == ThreadScope.passage
          ? _quoteController.text.trim()
          : null,
      rating: _rating,
    );

    if (mounted) {
      Navigator.pop(context);
      if (widget.onThreadCreated != null) {
        widget.onThreadCreated!();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thread "${title.isEmpty ? _selectedScope.label : title}" published!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Create Discussion Thread',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  _selectedScope == ThreadScope.passage
                      ? 'Start a conversation around this passage.'
                      : 'Share thoughts with ${widget.communityName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                if (_selectedScope == ThreadScope.passage &&
                    _quoteController.text.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.secondary,
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      _quoteController.text.trim(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Scope Segment Selector
                Text(
                  'Thread Scope',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ThreadScope.values.map((scope) {
                    final isSelected = _selectedScope == scope;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            scope.icon,
                            size: 14,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                          label: Text(
                            scope.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedScope = scope;
                              });
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Custom Topic Title Input
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: _selectedScope == ThreadScope.passage
                        ? 'Discussion title'
                        : 'Topic title',
                    hintText: _selectedScope == ThreadScope.passage
                        ? 'What do you want to explore?'
                        : 'Enter topic title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Conditional fields based on Scope
                if (_selectedScope == ThreadScope.chapter) ...[
                  TextField(
                    controller: _chapterController,
                    decoration: InputDecoration(
                      labelText: 'Chapter Name / Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_selectedScope == ThreadScope.passage) ...[
                  TextField(
                    controller: _quoteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Passage Excerpt / Quote (Optional)',
                      hintText: 'Paste or type excerpt...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Content Input
                TextField(
                  controller: _contentController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Your thought',
                    hintText: 'Write your interpretation or question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Passage/Chapter Rating Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Rating',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final starVal = index + 1;
                        return IconButton(
                          iconSize: 15,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            starVal <= _rating
                                ? LucideIcons.star
                                : LucideIcons.star,
                            color: starVal <= _rating
                                ? Colors.amber[700]
                                : Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = starVal.toDouble();
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFB45309,
                        ), // Ochre accent
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: const Text(
                        'Publish Thread',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
