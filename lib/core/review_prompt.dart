import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toefl_prep/core/clock.dart';

/// Ask for a review after the second finished mock, then at most once every 60 days.
bool shouldAskForReview({
  required int finishedMocks,
  required DateTime now,
  DateTime? lastAsked,
}) => finishedMocks >= 2 && (lastAsked == null || now.difference(lastAsked).inDays >= 60);

/// Google Play's in-app review sheet. Play also caps how often it really appears.
abstract interface class ReviewPrompter {
  /// Called once for every finished mock test.
  Future<void> mockFinished();
}

class PlayReviewPrompter implements ReviewPrompter {
  PlayReviewPrompter(this._preferences, this._clock, this._review);

  final SharedPreferencesAsync _preferences;
  final Clock _clock;
  final InAppReview _review;
  static const _countKey = 'reviewFinishedMocks';
  static const _askedKey = 'reviewLastAskedMs';

  @override
  Future<void> mockFinished() async {
    final count = (await _preferences.getInt(_countKey) ?? 0) + 1;
    await _preferences.setInt(_countKey, count);
    final askedMs = await _preferences.getInt(_askedKey);
    final now = _clock.now();
    final due = shouldAskForReview(
      finishedMocks: count,
      now: now,
      lastAsked: askedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(askedMs),
    );
    if (!due) return;
    try {
      if (!await _review.isAvailable()) return;
      await _preferences.setInt(_askedKey, now.millisecondsSinceEpoch);
      await _review.requestReview();
    } on PlatformException {
      // No Play Store on this device: nothing to show, and the test result is unaffected.
    }
  }
}

final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) =>
      PlayReviewPrompter(SharedPreferencesAsync(), ref.watch(clockProvider), InAppReview.instance),
);
