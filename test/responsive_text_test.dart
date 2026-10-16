import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/core/widgets/responsive_text.dart';

void main() {
  testWidgets('ResponsiveText.display scales without throwing errors on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 150,
            child: ResponsiveText.display(
              'The Brothers Karamazov Readers Club',
              maxLines: 2,
              minFontSize: 16,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The Brothers Karamazov Readers Club'), findsOneWidget);
  });

  testWidgets('ResponsiveText.title and ResponsiveText.label preserve hierarchy bounds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ResponsiveText.title('Important Discussion Title', maxLines: 2, minFontSize: 12.5),
              ResponsiveText.label('Chapter 4 • 12 Active Readers', maxLines: 1, minFontSize: 9.5),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Important Discussion Title'), findsOneWidget);
    expect(find.text('Chapter 4 • 12 Active Readers'), findsOneWidget);
  });
}
