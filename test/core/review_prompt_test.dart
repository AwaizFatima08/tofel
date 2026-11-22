import 'package:flutter_test/flutter_test.dart';
import 'package:toefl_prep/core/review_prompt.dart';

void main() {
  final now = DateTime(2026, 11, 22);

  test('never asks after the first mock', () {
    expect(shouldAskForReview(finishedMocks: 1, now: now), isFalse);
  });

  test('asks after the second mock when never asked', () {
    expect(shouldAskForReview(finishedMocks: 2, now: now), isTrue);
  });

  test('waits 60 days between asks', () {
    final asked = now.subtract(const Duration(days: 59));
    expect(shouldAskForReview(finishedMocks: 5, now: now, lastAsked: asked), isFalse);
    expect(
      shouldAskForReview(
        finishedMocks: 5,
        now: now,
        lastAsked: now.subtract(const Duration(days: 60)),
      ),
      isTrue,
    );
  });
}
