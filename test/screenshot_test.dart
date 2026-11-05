import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bookies/core/widgets/ambient_progress_bar.dart';
import 'package:bookies/core/widgets/passage_selection_context_menu.dart';
import 'package:bookies/domain/entities/live_participant_progress.dart';

Future<void> loadCustomFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final fontLoader = FontLoader(family);
  fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await fontLoader.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // 1. Load Segoe UI (Sans UI)
    await loadCustomFont('Segoe UI', r'C:\Windows\Fonts\segoeui.ttf');
    await loadCustomFont('Segoe UI Bold', r'C:\Windows\Fonts\segoeuib.ttf');

    // 2. Load Georgia (Serif book text)
    await loadCustomFont('Georgia', r'C:\Windows\Fonts\georgia.ttf');
    await loadCustomFont('Georgia Italic', r'C:\Windows\Fonts\georgiai.ttf');

    // 3. Load Material Icons
    await loadCustomFont(
      'MaterialIcons',
      r'C:\flutter_dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    );

    // 4. Load Lucide Icons
    final home = Platform.environment['LOCALAPPDATA'] ?? '';
    final lucidePath =
        '$home\\Pub\\Cache\\hosted\\pub.dev\\lucide_icons_flutter-3.1.15\\assets\\lucide.ttf';
    await loadCustomFont('packages/lucide_icons_flutter/Lucide', lucidePath);
  });

  testWidgets('capture reader view screenshot with real fonts', (WidgetTester tester) async {
    final GlobalKey repaintBoundaryKey = GlobalKey();

    tester.view.physicalSize = const Size(1170, 2532); // iPhone 14/15 Pro
    tester.view.devicePixelRatio = 3.0;

    final participants = [
      LiveParticipantProgress(
        userId: 'm-1',
        displayName: 'Marcus',
        progression: 0.28,
        lastUpdated: DateTime.now(),
      ),
      LiveParticipantProgress(
        userId: 'e-2',
        displayName: 'Elena',
        progression: 0.50,
        lastUpdated: DateTime.now(),
      ),
      LiveParticipantProgress(
        userId: 'p-3',
        displayName: 'Priya',
        progression: 0.82,
        lastUpdated: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Segoe UI',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB45309),
            brightness: Brightness.light,
          ),
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: repaintBoundaryKey,
            child: Container(
              color: const Color(0xFFFAF8F5), // warm literary paper
              child: SafeArea(
                child: Column(
                  children: [
                    // Phone Status Bar Simulation (Clean Minimalist)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '9:41',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4036),
                            ),
                          ),
                          Container(
                            width: 68,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5DFD7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.wifi, size: 15, color: Color(0xFF4A4036)),
                              SizedBox(width: 5),
                              Icon(Icons.battery_full, size: 15, color: Color(0xFF4A4036)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reader Top Bar (Faithfully matches ReaderView AppBar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF8F5),
                        border: Border(bottom: BorderSide(color: Color(0xFFEBE5DF))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // TOC List Tree icon
                          const Icon(
                            LucideIcons.listTree,
                            size: 20,
                            color: Color(0xFF2C241E),
                          ),
                          // Centered Book Title & Community Dropdown
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'The Secret History',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Segoe UI',
                                  color: Color(0xFF2C241E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB45309).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFB45309).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.users, size: 12, color: Color(0xFFB45309)),
                                    SizedBox(width: 4),
                                    Text(
                                      'The Classics Circle',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Icon(LucideIcons.chevronDown, size: 12, color: Color(0xFFB45309)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Reading Settings Sliders icon
                          const Icon(
                            LucideIcons.slidersHorizontal,
                            size: 20,
                            color: Color(0xFF2C241E),
                          ),
                        ],
                      ),
                    ),

                    // Ambient Progress Bar with Live Participant Beads
                    AmbientProgressBar(
                      progress: 0.42,
                      participants: participants,
                    ),

                    // Book Content Surface & Floating Context Menu
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 22.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CHAPTER I • PROLOGUE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8C827A),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'The snow in the mountains was melting and Bunny had been dead for several weeks before we came to understand the gravity of our situation.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.7,
                                      fontFamily: 'Georgia',
                                      color: Color(0xFF2C241E),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Selected & Highlighted Passage with native handles
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB45309).withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(3),
                                          border: const Border(
                                            bottom: BorderSide(color: Color(0xFFB45309), width: 2),
                                          ),
                                        ),
                                        child: const Text(
                                          '“Beauty is terror. Whatever we call beautiful, we quiver before it. And what could be more terrifying and beautiful, to souls like the Greeks or our own, than to lose control completely?”',
                                          style: TextStyle(
                                            fontSize: 17,
                                            height: 1.7,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Georgia',
                                            color: Color(0xFF1E1711),
                                          ),
                                        ),
                                      ),
                                      // Start Teardrop Selection Handle
                                      Positioned(
                                        left: -6,
                                        top: -10,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFB45309),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // End Teardrop Selection Handle
                                      Positioned(
                                        right: -6,
                                        bottom: -6,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFB45309),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Julian had spoken with such quiet conviction that for a moment no one in the room dared to breathe. Henry leaned back in his wicker chair, hands steepled.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.7,
                                      fontFamily: 'Georgia',
                                      color: Color(0xFF2C241E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Floating PassageSelectionContextMenu (Faithfully placed near the bottom)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 24,
                            child: PassageSelectionContextMenu(
                              selectedText: '“Beauty is terror. Whatever we call beautiful, we quiver before it. And what could be more terrifying and beautiful, to souls like the Greeks or our own, than to lose control completely?”',
                              backgroundColor: const Color(0xFFFAF8F5),
                              foregroundColor: const Color(0xFF2C241E),
                              onStartThread: () {},
                              onSaveQuote: () {},
                              onHighlight: () {},
                              onDismiss: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Clean Bottom Home Indicator Bar Only (NO chapter or progress indicator at bottom!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 4),
                      child: Center(
                        child: Container(
                          width: 134,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C241E).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(2.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        File('reader_screenshot.png').writeAsBytesSync(buffer);
        print('SAVED_REAL_SCREENSHOT_SUCCESS: ${buffer.length} bytes');

        // Copy directly to backend assets
        final targetAsset = File(r'c:\flutter_dev\projects\bookies-backend\assets\reader-preview.png');
        targetAsset.parent.createSync(recursive: true);
        targetAsset.writeAsBytesSync(buffer);
        print('COPIED_TO_BACKEND_ASSETS: ${targetAsset.path}');
      }
    }
  });
}
