import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/attempts/attempt_repository.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/core/result.dart';
import 'package:toefl_prep/features/exam/exam_notifier.dart';
import 'package:toefl_prep/router.dart';
import 'package:toefl_prep/ui/audio_widgets.dart';
import 'package:toefl_prep/ui/question_view.dart';

import '../attempts/attempt_repository_test.dart' show MemoryStore;

/// Opens real screens with the built content, so a broken layout or a hang fails here, not on a phone.
void main() {
  late ProviderContainer container;
  late MemoryRecorder recorder;

  /// Lets file reads and isolates finish, then draws.
  Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, String location) async {
    // A tall phone (412 × 1000 logical pixels), so intro buttons are on screen.
    tester.view.physicalSize = const Size(1236, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    recorder = MemoryRecorder();
    container = ProviderContainer(
      overrides: [
        assetReaderProvider.overrideWithValue((path) async => File(path).readAsString()),
        attemptStoreProvider.overrideWithValue(MemoryStore()),
        speakerProvider.overrideWithValue(SilentSpeaker()),
        recorderProvider.overrideWithValue(recorder),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ToeflApp()),
    );
    container.read(routerProvider).go(location);
    await settle(tester, rounds: 20);
  }

  testWidgets('the paper screen shows the four sections', (tester) async {
    await open(tester, '/paper/toefl-01');
    expect(find.text('Reading'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Start mock test'), 200);
    expect(find.text('Start mock test'), findsOneWidget);
  });

  testWidgets('a whole mock runs through every part to the results', (tester) async {
    await open(tester, '/');
    final started = await tester.runAsync(
      () => container.read(attemptRepositoryProvider).start(paperId: 'toefl-01', seconds: 1200),
    );
    final id = (started! as Ok<Attempt, StorageFailure>).value.id;
    container.read(routerProvider).go('/exam/$id');
    await settle(tester, rounds: 40);
    final notifier = container.read(examProvider(id).notifier);

    // Each part: the intro, Begin, then the right task screen.
    final expected = [CtwView, CtwView, ChoiceList, ChoiceList, BasView, null, null, SpeakRunner];
    for (final (part, widget) in expected.indexed) {
      expect(find.text('Begin'), findsOneWidget, reason: 'part ${part + 1} intro');
      await tester.tap(find.text('Begin'));
      await settle(tester);
      if (widget != null) expect(find.byType(widget), findsWidgets, reason: 'part ${part + 1}');
      if (widget == SpeakRunner) break;
      unawaited(notifier.endStage());
      await settle(tester);
    }

    // Speaking runs by itself: 7 sentences to repeat, then 4 interview answers.
    for (
      var answers = 0;
      answers < 16 && find.byType(SpeakRunner).evaluate().isNotEmpty;
      answers++
    ) {
      await tester.pump(const Duration(seconds: 50));
      await settle(tester, rounds: 4);
      if (find.text('Begin').evaluate().isNotEmpty) {
        await tester.tap(find.text('Begin'));
        await settle(tester);
      }
    }
    await settle(tester, rounds: 20);
    expect(find.text('Estimated overall band'), findsOneWidget);
    expect(recorder.saved, hasLength(11));

    for (final location in ['/review/$id', '/rate/$id/writing', '/rate/$id/speaking']) {
      container.read(routerProvider).go(location);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: location);
    }
    container.read(routerProvider).go('/rate/$id/speaking');
    await settle(tester);
    expect(find.text('Play my answer'), findsWidgets);
  });

  testWidgets('practice, lessons, guide and vocabulary screens open', (tester) async {
    await open(tester, '/');
    const locations = [
      '/practice/reading/ctw',
      '/practice/reading/rap',
      '/practice/listening/lcv',
      '/practice/listening/lcr',
      '/practice/writing/bas',
      '/topic/writing/eml',
      '/topic/speaking/lrp',
      '/task/writing/we-p0001',
      '/task/writing/wd-p0001',
      '/task/speaking/sr-ps001',
      '/task/speaking/si-ps001',
      '/lesson/ctw',
      '/lesson/int',
      '/guide/exam-format',
      '/vocab',
      '/about',
    ];
    for (final location in locations) {
      container.read(routerProvider).go(location);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: location);
      expect(find.textContaining('Could not load'), findsNothing, reason: location);
    }
  });
}
