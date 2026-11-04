import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/attempts/attempt_repository.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/result.dart';
import 'package:toefl_prep/features/exam/exam_notifier.dart';
import 'package:toefl_prep/features/practice/practice_notifier.dart';
import 'package:toefl_prep/router.dart';
import 'package:toefl_prep/ui/audio_widgets.dart';
import 'package:toefl_prep/ui/question_view.dart';

import '../test/attempts/attempt_repository_test.dart' show MemoryStore;

/// Play Store phone screenshots, 1080 × 2400, drawn with the real Roboto and Material Icons fonts.
/// Run: flutter test test_screenshots, then copy shots/ to store-assets/screenshots/ (as RGB, no alpha).
void main() {
  late ProviderContainer container;
  final root = GlobalKey();

  setUpAll(() async {
    final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    }

    await load('Roboto', [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Italic.ttf',
      'Roboto-Light.ttf',
    ]);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester, rounds: 4);
    // Full device pixels, so the Play listing gets 1080 × 2400 images.
    final boundary = root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('test_screenshots/shots/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> go(WidgetTester tester, String location) async {
    container.read(routerProvider).go(location);
    await settle(tester);
  }

  /// The right answer to an auto-scored question.
  String correct(Question question) => switch (question.type) {
    QuestionType.ctw => [for (final gap in question.gaps) gap.missing].join('|'),
    QuestionType.mc || QuestionType.lcr => '${question.answer.first}',
    QuestionType.bas => [for (var i = 0; i < question.chunks.length; i++) i].join(','),
    // An email or discussion post only has to exist to be rated.
    QuestionType.email || QuestionType.disc => question.explanation,
    _ => '',
  };

  testWidgets('store screenshots', (tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    addTearDown(() => WidgetsApp.debugAllowBannerOverride = true);
    // A 1080 × 2400 phone at 2.625 dpr: 411 × 914 logical pixels.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    container = ProviderContainer(
      overrides: [
        assetReaderProvider.overrideWithValue((path) async => File(path).readAsString()),
        attemptStoreProvider.overrideWithValue(MemoryStore()),
        speakerProvider.overrideWithValue(SilentSpeaker()),
        recorderProvider.overrideWithValue(MemoryRecorder()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: UncontrolledProviderScope(container: container, child: const ToeflApp()),
      ),
    );
    await settle(tester, rounds: 20);
    await shot(tester, '01-home');

    await go(tester, '/paper/toefl-01');
    await shot(tester, '02-paper');

    // A mock with most answers right, so the results look like a good candidate's.
    final started = await tester.runAsync(
      () => container.read(attemptRepositoryProvider).start(paperId: 'toefl-01', seconds: 1200),
    );
    final id = (started! as Ok<Attempt, StorageFailure>).value.id;
    await go(tester, '/exam/$id');
    await settle(tester, rounds: 30);
    final notifier = container.read(examProvider(id).notifier);

    Future<void> answerStage() async {
      final state = container.read(examProvider(id)).value!;
      for (final (i, question) in state.questions.indexed) {
        if (question.type.isAutoScored && i % 6 != 5 ||
            question.type == QuestionType.email ||
            question.type == QuestionType.disc) {
          await tester.runAsync(() => notifier.respondTo(question.id, correct(question)));
        }
      }
      await settle(tester, rounds: 3);
    }

    for (var part = 0; find.byType(SpeakRunner).evaluate().isEmpty && part < 8; part++) {
      // Answers saved before the part opens show in its fields.
      await answerStage();
      await tester.tap(find.text('Begin'));
      await settle(tester);
      if (part == 0) await shot(tester, '03-reading');
      if (part == 2) await shot(tester, '04-listening');
      if (find.byType(SpeakRunner).evaluate().isNotEmpty) break;
      unawaited(notifier.endStage());
      await settle(tester);
    }
    for (var n = 0; n < 16 && find.byType(SpeakRunner).evaluate().isNotEmpty; n++) {
      await tester.pump(const Duration(seconds: 50));
      await settle(tester, rounds: 4);
      if (find.text('Begin').evaluate().isNotEmpty) {
        await tester.tap(find.text('Begin'));
        await settle(tester);
      }
    }
    await settle(tester);
    final review = container.read(reviewProvider(id).notifier);
    final done = await tester.runAsync(() => container.read(reviewProvider(id).future));
    for (final (i, question)
        in done!.sitting.stages.expand(done.sitting.questionsOf).where((q) => !q.type.isAutoScored).indexed) {
      await tester.runAsync(() => review.rate(question.id, i.isEven ? 4 : 5));
    }
    await go(tester, '/results/$id');
    await shot(tester, '05-results');

    await go(tester, '/practice/listening/lcv');
    await settle(tester);
    final practice = container.read(practiceProvider(const PracticeKey('listening', 'lcv'))).value!;
    await tester.tap(find.byType(OptionTile).at(practice.question.answer.first));
    await settle(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await shot(tester, '06-explained');

    await go(tester, '/task/speaking/si-ps001');
    await tester.tap(find.textContaining('Start'));
    await settle(tester, rounds: 6);
    await tester.pump(const Duration(seconds: 12));
    await shot(tester, '07-speaking');

    await go(tester, '/lesson/rap');
    await shot(tester, '08-lesson');
  });
}
