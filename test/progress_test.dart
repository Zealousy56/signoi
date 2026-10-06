import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signoi/pages/progress.dart';

void main() {
  Widget buildProgress({
    required int level,
    required double experience,
    required bool isActive,
  }) {
    return MaterialApp(
      home: ProgressPage(
        level: level,
        experience: experience,
        isActive: isActive,
      ),
    );
  }

  int displayedPercent(WidgetTester tester) {
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(Text),
      ),
    );
    return int.parse(label.data!.replaceAll('%', ''));
  }

  testWidgets('accumulated experience animates on first visit only', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProgress(level: 1, experience: 0.0, isActive: false),
    );
    await tester.pumpWidget(
      buildProgress(level: 1, experience: 0.3, isActive: false),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0%'), findsOneWidget);

    await tester.pumpWidget(
      buildProgress(level: 1, experience: 0.3, isActive: true),
    );
    final startTop = tester.widget<Positioned>(find.byType(Positioned)).top!;
    await tester.pump(const Duration(milliseconds: 450));
    final midpointTop = tester.widget<Positioned>(find.byType(Positioned)).top!;
    expect(find.text('15%'), findsOneWidget);
    expect(midpointTop, lessThan(startTop - 30));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('30%'), findsOneWidget);

    await tester.pumpWidget(
      buildProgress(level: 1, experience: 0.3, isActive: false),
    );
    await tester.pumpWidget(
      buildProgress(level: 1, experience: 0.3, isActive: true),
    );
    await tester.pump();
    expect(find.text('30%'), findsOneWidget);
  });

  testWidgets('level-up fills, snaps empty, then rises to current experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProgress(level: 1, experience: 0.7, isActive: true),
    );

    await tester.pumpWidget(
      buildProgress(level: 2, experience: 0.2, isActive: true),
    );
    await tester.pump(const Duration(milliseconds: 899));
    expect(displayedPercent(tester), 100);

    await tester.pump(const Duration(milliseconds: 17));
    expect(displayedPercent(tester), 0);

    await tester.pump(const Duration(milliseconds: 450));
    expect(displayedPercent(tester), inInclusiveRange(5, 15));

    await tester.pump(const Duration(milliseconds: 450));
    expect(displayedPercent(tester), 20);
  });
}
