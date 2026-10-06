import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signoi/pages/goals.dart';

void main() {
  testWidgets('completing a short-term goal awards progress', (tester) async {
    double? earnedExperience;

    await tester.pumpWidget(
      MaterialApp(
        home: GoalsPage(
          items: const [],
          onItemsChanged: (_) {},
          shortTermItems: [
            {
              'title': 'Short goal',
              'steps': [
                {'text': 'Finish', 'checked': true},
              ],
              'stockProgress': 0.0,
            },
          ],
          onShortTermItemsChanged: (_) {},
          onExperienceEarned: (amount) => earnedExperience = amount,
        ),
      ),
    );

    await tester.tap(find.text('Short-term'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Complete'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(earnedExperience, 0.3);
  });
}
