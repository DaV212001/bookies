import 'package:flutter/material.dart';
import 'package:bookies/domain/entities/live_participant_progress.dart';
import '../theme/app_colors.dart';

class AmbientProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final List<LiveParticipantProgress> participants;
  final void Function(LiveParticipantProgress participant)? onParticipantTapped;

  const AmbientProgressBar({
    super.key,
    required this.progress,
    this.participants = const [],
    this.onParticipantTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readerColors = theme.extension<ReaderColors>();
    final progressColor = readerColors?.progressFill ?? theme.colorScheme.primary;

    if (participants.isEmpty) {
      return Container(
        width: double.infinity,
        height: 4.0,
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
              height: 4.0,
              color: progressColor,
            );
          },
        ),
      );
    }

    // Social Reading Track with Participant Avatar Badges
    const double trackHeight = 28.0;
    const double avatarSize = 22.0;

    return Container(
      width: double.infinity,
      height: trackHeight,
      color: theme.colorScheme.surface.withOpacity(0.4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final usableWidth = (maxW - avatarSize).clamp(1.0, maxW);

          return Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // 1. Base track background line
              Positioned(
                left: 0,
                right: 0,
                top: (trackHeight - 3.0) / 2,
                child: Container(
                  height: 3.0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Local reader's progress fill
              Positioned(
                left: 0,
                top: (trackHeight - 3.0) / 2,
                child: Container(
                  width: maxW * progress.clamp(0.0, 1.0),
                  height: 3.0,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 3. Social Participant Avatar Indicators
              for (final participant in participants)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: usableWidth * participant.progression.clamp(0.0, 1.0),
                  top: (trackHeight - avatarSize) / 2,
                  child: Tooltip(
                    message:
                        '${participant.displayName} • ${(participant.progression * 100).toInt()}%'
                        '${participant.chapterTitle != null ? ' (${participant.chapterTitle})' : ''}',
                    preferBelow: true,
                    child: GestureDetector(
                      onTap: () => onParticipantTapped?.call(participant),
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarSize / 2,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: participant.avatarUrl != null &&
                                  participant.avatarUrl!.isNotEmpty
                              ? NetworkImage(participant.avatarUrl!)
                              : null,
                          child: participant.avatarUrl == null ||
                                  participant.avatarUrl!.isEmpty
                              ? Text(
                                  participant.displayName.isNotEmpty
                                      ? participant.displayName[0].toUpperCase()
                                      : 'R',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
