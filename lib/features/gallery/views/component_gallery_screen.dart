import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/marginalia_card.dart';
import '../../../core/widgets/quote_card.dart';
import '../../../core/widgets/reaction_chip.dart';
import '../../../core/widgets/ambient_progress_bar.dart';
import '../../../core/widgets/reading_well.dart';
import '../../../core/widgets/margin_discussion_indicator.dart';
import '../../../core/widgets/discussion_modal.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  ThemeData _currentTheme = AppTheme.parchmentLight;
  String _themeName = 'Light (Parchment)';

  void _cycleTheme() {
    setState(() {
      if (_themeName == 'Light (Parchment)') {
        _currentTheme = AppTheme.sepiaWarm;
        _themeName = 'Sepia (Warm)';
      } else if (_themeName == 'Sepia (Warm)') {
        _currentTheme = AppTheme.charcoalNight;
        _themeName = 'Dark (Charcoal)';
      } else {
        _currentTheme = AppTheme.parchmentLight;
        _themeName = 'Light (Parchment)';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _currentTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Component Gallery'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  tooltip: 'Cycle Theme',
                  onPressed: _cycleTheme,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Theme: $_themeName', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.l),
                  
                  // Ambient Progress Bar
                  Text('AmbientProgressBar', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  const AmbientProgressBar(progress: 0.65),
                  const SizedBox(height: AppSpacing.l),

                  // Reading Well (Demo text)
                  Text('ReadingWell (Typography)', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  ReadingWell(
                    child: Text(
                      'This is a demonstration of the body text typography within the ReadingWell constraints. '
                      'It should constrain the maximum width for optimal deep reading comfort.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // MarginaliaCard & QuoteCard
                  Text('MarginaliaCard & QuoteCard', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  MarginaliaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const QuoteCard(
                          text: '"Reading requires minimal cognitive load, meaning comments and discussions should never appear inline as raw text that breaks up paragraphs."',
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text('This is a profound thought.', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // PrimaryButton
                  Text('PrimaryButton', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  PrimaryButton(
                    label: 'Import File',
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // ReactionChip
                  Text('ReactionChip', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      ReactionChip(label: 'Insightful', isActive: true, onTap: () {}),
                      const SizedBox(width: AppSpacing.xs),
                      ReactionChip(label: 'Funny', isActive: false, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // MarginDiscussionIndicator & DiscussionModal
                  Text('MarginDiscussionIndicator & DiscussionModal', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const MarginDiscussionIndicator(),
                      const SizedBox(width: AppSpacing.s),
                      PrimaryButton(
                        label: 'Show Modal',
                        onPressed: () {
                          DiscussionModal.show(
                            context: context,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Discussion Thread', style: Theme.of(context).textTheme.headlineMedium),
                                const SizedBox(height: AppSpacing.m),
                                const QuoteCard(text: 'Selected text for context'),
                                const SizedBox(height: AppSpacing.m),
                                Text('Wow, that is so interesting!', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
