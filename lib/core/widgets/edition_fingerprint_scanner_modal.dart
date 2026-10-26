import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bookies/core/theme/app_colors.dart';
import 'package:bookies/core/theme/app_radius.dart';

class EditionFingerprintScannerModal extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<FingerprintScanResult> Function(
    void Function(String message, double progress) updateProgress,
  ) onScan;

  const EditionFingerprintScannerModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.onScan,
  });

  static Future<FingerprintScanResult?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Future<FingerprintScanResult> Function(
      void Function(String message, double progress) updateProgress,
    ) onScan,
  }) {
    return showModalBottomSheet<FingerprintScanResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditionFingerprintScannerModal(
        title: title,
        subtitle: subtitle,
        onScan: onScan,
      ),
    );
  }

  @override
  State<EditionFingerprintScannerModal> createState() =>
      _EditionFingerprintScannerModalState();
}

class FingerprintScanResult {
  final bool isSuccess;
  final bool isMatch;
  final String computedFingerprint;
  final String? expectedFingerprint;
  final String? errorMessage;
  final dynamic payload;

  const FingerprintScanResult({
    required this.isSuccess,
    required this.isMatch,
    required this.computedFingerprint,
    this.expectedFingerprint,
    this.errorMessage,
    this.payload,
  });
}

class _EditionFingerprintScannerModalState
    extends State<EditionFingerprintScannerModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String _currentStage = 'Initializing scanner...';
  double _progress = 0.05;
  FingerprintScanResult? _result;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _executeScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _executeScan() async {
    try {
      final res = await widget.onScan((message, progress) {
        if (mounted) {
          setState(() {
            _currentStage = message;
            _progress = progress.clamp(0.0, 1.0);
          });
        }
      });

      if (!mounted) return;

      setState(() {
        _result = res;
        _isProcessing = false;
        _progress = 1.0;
        if (res.isMatch) {
          _currentStage = 'Structural sync verified! (100% Match)';
        } else {
          _currentStage = 'Edition structural mismatch detected.';
        }
      });

      if (res.isMatch && res.isSuccess) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          Navigator.of(context).pop(_result);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _currentStage = 'Scan error: $e';
        _result = FingerprintScanResult(
          isSuccess: false,
          isMatch: false,
          computedFingerprint: '',
          errorMessage: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color stateColor;
    if (_isProcessing) {
      stateColor = AppColors.secondary;
    } else if (_result?.isMatch == true) {
      stateColor = const Color(0xFF16A34A); // Vibrant green
    } else {
      stateColor = Colors.amber.shade800; // Discrepancy warning
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header title
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),

            // Center Scanner Radar Animation
            SizedBox(
              height: 140,
              width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(140, 140),
                        painter: _BiometricRadarPainter(
                          animationValue: _pulseController.value,
                          ringColor: stateColor,
                          isScanning: _isProcessing,
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isProcessing
                            ? LucideIcons.fingerprint
                            : (_result?.isMatch == true
                                ? LucideIcons.checkCheck
                                : LucideIcons.triangleAlert),
                        color: stateColor,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Animated Status Stage Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _currentStage,
                key: ValueKey(_currentStage),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: stateColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Ambient Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                ),
              ),
            ),

            // Discrepancy details if mismatched
            if (!_isProcessing && _result != null && !_result!.isMatch) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.gitCompare, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'CFI Anchor Fingerprint Mismatch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Host Canonical:\n${_formatFp(_result?.expectedFingerprint)}\n\n'
                      'Your Edition:\n${_formatFp(_result?.computedFingerprint)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(_result),
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFp(String? fp) {
    if (fp == null || fp.isEmpty) return '(None / Not set)';
    if (fp.length > 28) return '${fp.substring(0, 24)}...';
    return fp;
  }
}

class _BiometricRadarPainter extends CustomPainter {
  final double animationValue;
  final Color ringColor;
  final bool isScanning;

  _BiometricRadarPainter({
    required this.animationValue,
    required this.ringColor,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (isScanning) {
      // 1. Concentric pulsing radar waves
      for (int i = 0; i < 3; i++) {
        final waveVal = (animationValue + (i * 0.33)) % 1.0;
        final radius = 38.0 + (waveVal * 30.0);
        final alpha = (1.0 - waveVal) * 0.45;
        final paint = Paint()
          ..color = ringColor.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, radius, paint);
      }

      // 2. Rotating orbital data tick
      final sweepAngle = animationValue * 2 * math.pi;
      final tickRadius = 56.0;
      final tickOffset = Offset(
        center.dx + tickRadius * math.cos(sweepAngle),
        center.dy + tickRadius * math.sin(sweepAngle),
      );
      final tickPaint = Paint()
        ..color = ringColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tickOffset, 3.0, tickPaint);
    } else {
      // Static completed glow ring
      final paint = Paint()
        ..color = ringColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, 52, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BiometricRadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.isScanning != isScanning;
  }
}
