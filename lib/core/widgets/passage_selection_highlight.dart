import 'package:flutter/material.dart';

class InteractivePassageSelectionHighlight extends StatefulWidget {
  final String currentSelectedText;
  final Offset selectionPosition;
  final VoidCallback onExpandRight;
  final VoidCallback onShortenRight;
  final VoidCallback onExpandLeft;
  final VoidCallback onShortenLeft;

  const InteractivePassageSelectionHighlight({
    super.key,
    required this.currentSelectedText,
    required this.selectionPosition,
    required this.onExpandRight,
    required this.onShortenRight,
    required this.onExpandLeft,
    required this.onShortenLeft,
  });

  @override
  State<InteractivePassageSelectionHighlight> createState() =>
      _InteractivePassageSelectionHighlightState();
}

class _InteractivePassageSelectionHighlightState
    extends State<InteractivePassageSelectionHighlight> {
  double _dragAccumulatorRight = 0.0;
  double _dragAccumulatorLeft = 0.0;

  static const double _dragThreshold = 18.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final double topPos = (widget.selectionPosition.dy - 24)
        .clamp(70.0, MediaQuery.of(context).size.height - 150);
    final double actualWidth = (screenWidth - 48).clamp(200.0, 360.0);

    const primaryColor = Color(0xFFB45309); // Ochre theme color

    return Positioned(
      top: topPos,
      left: ((screenWidth - actualWidth) / 2).clamp(16.0, screenWidth - actualWidth - 16.0),
      child: Container(
        width: actualWidth,
        height: 48,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.22), // Ochre highlight tint
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Center Selected Text Preview inside highlight box
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.currentSelectedText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.amber[200] : const Color(0xFF78350F),
                  ),
                ),
              ),
            ),

            // Left Native Teardrop Selection Handle (Start Handle)
            Positioned(
              left: -10,
              top: -8,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _dragAccumulatorLeft += details.delta.dx;
                  if (_dragAccumulatorLeft < -_dragThreshold) {
                    widget.onExpandLeft();
                    _dragAccumulatorLeft = 0.0;
                  } else if (_dragAccumulatorLeft > _dragThreshold) {
                    widget.onShortenLeft();
                    _dragAccumulatorLeft = 0.0;
                  }
                },
                onHorizontalDragEnd: (_) {
                  _dragAccumulatorLeft = 0.0;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: SizedBox(
                    width: 24,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Vertical Selection Guide Line
                        Positioned(
                          top: 8,
                          bottom: 12,
                          child: Container(
                            width: 2.5,
                            color: primaryColor,
                          ),
                        ),
                        // Native Teardrop Handle Pin (Top Left Teardrop)
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(0),
                              ),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Right Native Teardrop Selection Handle (End Handle)
            Positioned(
              right: -10,
              bottom: -8,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _dragAccumulatorRight += details.delta.dx;
                  if (_dragAccumulatorRight > _dragThreshold) {
                    widget.onExpandRight();
                    _dragAccumulatorRight = 0.0;
                  } else if (_dragAccumulatorRight < -_dragThreshold) {
                    widget.onShortenRight();
                    _dragAccumulatorRight = 0.0;
                  }
                },
                onHorizontalDragEnd: (_) {
                  _dragAccumulatorRight = 0.0;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: SizedBox(
                    width: 24,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Vertical Selection Guide Line
                        Positioned(
                          top: 12,
                          bottom: 8,
                          child: Container(
                            width: 2.5,
                            color: primaryColor,
                          ),
                        ),
                        // Native Teardrop Handle Pin (Bottom Right Teardrop)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
