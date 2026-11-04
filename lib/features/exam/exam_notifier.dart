import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/attempts/attempt_repository.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/clock.dart';
import 'package:toefl_prep/core/result.dart';
import 'package:toefl_prep/core/scoring.dart';
import 'package:toefl_prep/settings/settings_repository.dart';

class ExamState {
  const ExamState({required this.sitting, required this.attempt, required this.catalog});

  final Sitting sitting;
  final Attempt attempt;
  final Catalog catalog;

  Stage get stage => sitting.stages[attempt.stage];

  List<Question> get questions => sitting.questionsOf(stage);

  Question get question => questions[attempt.currentIndex.clamp(0, questions.length - 1)];

  QuestionSet? setOf(Question question) => sitting.sets[question.setId];

  bool get isLastStage => attempt.stage == sitting.stages.length - 1;

  /// The recording that must be heard before [question] is shown: its set's, or its own line.
  String audioKey(Question question) => question.setId ?? question.id;

  ExamState withAttempt(Attempt attempt) =>
      ExamState(sitting: sitting, attempt: attempt, catalog: catalog);

  MockResult result() => scoreSitting(sitting, attempt.responses, attempt.ratings);
}

/// Loads an attempt with its paper; used by the exam, results and review screens.
Future<ExamState> loadExamState(Ref ref, String attemptId) async {
  final attempt = await ref.read(attemptRepositoryProvider).byId(attemptId);
  if (attempt == null) throw StorageFailure('not-found:$attemptId');
  return _withSitting(ref, attempt);
}

Future<ExamState> _withSitting(Ref ref, Attempt attempt) async {
  final content = ref.read(contentRepositoryProvider);
  final papers = await content.papers();
  final paper = papers.where((p) => p.id == attempt.paperId).firstOrNull;
  if (paper == null) throw ContentFailure('missing-paper:${attempt.paperId}');
  final catalog = await content.catalog();
  final loaded = await content.sitting(paper, catalog, routes: attempt.routes);
  return switch (loaded) {
    Ok(:final value) => ExamState(sitting: value, attempt: attempt, catalog: catalog),
    Err(:final failure) => throw failure,
  };
}

MockScore scoreOf(MockResult result) => MockScore(
  reading: result.sections['reading']!.band,
  listening: result.sections['listening']!.band,
  writing: result.sections['writing']!.band,
  speaking: result.sections['speaking']!.band,
  overall: result.overall,
  complete: result.complete,
);

/// Results and review of a finished attempt; the candidate's ratings of writing and speaking go through here.
class ReviewNotifier extends AsyncNotifier<ExamState> {
  ReviewNotifier(this.attemptId);

  final String attemptId;

  @override
  Future<ExamState> build() => loadExamState(ref, attemptId);

  /// Saves the candidate's 0-5 rating of a writing or speaking task and rescores the mock.
  Future<void> rate(String questionId, int rating) async {
    final current = await future;
    final ratings = {...current.attempt.ratings, questionId: rating};
    final rated = current.attempt.copyWith(ratings: ratings);
    final next = rated.copyWith(score: scoreOf(current.withAttempt(rated).result()));
    await ref.read(attemptRepositoryProvider).update(attemptId, (_) => next);
    state = AsyncData(current.withAttempt(next));
  }
}

final reviewProvider = AsyncNotifierProvider.autoDispose.family<ReviewNotifier, ExamState, String>(
  ReviewNotifier.new,
);

/// Runs one mock: the stage clocks, answers, marks, the routing to a second module and the final score.
class ExamNotifier extends AsyncNotifier<ExamState> {
  ExamNotifier(this.attemptId);

  final String attemptId;

  static const _saveEverySeconds = 15;
  Timer? _timer;

  AttemptRepository get _repository => ref.read(attemptRepositoryProvider);

  @override
  Future<ExamState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final loaded = await loadExamState(ref, attemptId);
    // The state is only set once build returns, so start a resumed stage's clock just after.
    if (!loaded.attempt.isFinished && loaded.attempt.stageStarted) {
      unawaited(Future.microtask(resumeTimer));
    }
    return loaded;
  }

  void resumeTimer() {
    final current = state.value;
    if (current == null ||
        current.attempt.isFinished ||
        !current.attempt.stageStarted ||
        !current.stage.isTimed) {
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_tick()));
  }

  /// Stops the clock and saves the time left, when the candidate leaves the test.
  Future<void> pauseTimer() async {
    _timer?.cancel();
    final current = state.value;
    if (current == null || current.attempt.isFinished) return;
    await _persist(current.attempt);
  }

  Future<void> _tick() async {
    final current = state.value;
    if (current == null) return;
    final remaining = current.attempt.remainingSeconds - 1;
    if (remaining <= 0) {
      await endStage();
      return;
    }
    final next = current.attempt.copyWith(remainingSeconds: remaining);
    state = AsyncData(current.withAttempt(next));
    if (remaining % _saveEverySeconds == 0) await _persist(next);
  }

  Future<void> _persist(Attempt attempt) async {
    await _repository.update(attemptId, (_) => attempt);
  }

  Future<void> _apply(Attempt Function(Attempt) change) async {
    final current = state.value;
    if (current == null || current.attempt.isFinished) return;
    final next = change(current.attempt);
    await _persist(next);
    state = AsyncData(current.withAttempt(next));
  }

  /// Starts the clock of the current stage after its intro screen.
  Future<void> beginStage() async {
    await _apply((attempt) => attempt.copyWith(stageStarted: true));
    resumeTimer();
  }

  Future<void> respond(String response) => respondTo(state.value!.question.id, response);

  Future<void> respondTo(String questionId, String response) => _apply((attempt) {
    final responses = {...attempt.responses};
    if (response.isEmpty) {
      responses.remove(questionId);
    } else {
      responses[questionId] = response;
    }
    return attempt.copyWith(responses: responses);
  });

  /// Records that a listening recording has been heard; it will not play again.
  Future<void> markPlayed(String key) =>
      _apply((attempt) => attempt.copyWith(played: {...attempt.played, key}));

  Future<void> toggleFlag() => _apply((attempt) {
    final id = state.value!.question.id;
    final flagged = {...attempt.flagged};
    if (!flagged.remove(id)) flagged.add(id);
    return attempt.copyWith(flagged: flagged);
  });

  Future<void> goTo(int index) => _apply((attempt) => attempt.copyWith(currentIndex: index));

  /// Closes the current stage (time up or the candidate moves on). Ending a router module fixes which
  /// second module follows; ending the last stage marks the mock.
  Future<void> endStage() async {
    _timer?.cancel();
    final current = state.value;
    if (current == null || current.attempt.isFinished) return;
    if (current.isLastStage) {
      await _finish(current);
      return;
    }
    var attempt = current.attempt;
    final stage = current.stage;
    if (stage.isRouter) {
      final points = routerPoints(current.sitting, stage.section, attempt.responses);
      final upper = points >= current.catalog.section(stage.section).upperAt;
      attempt = attempt.copyWith(
        routes: {...attempt.routes, stage.section: upper ? 'upper' : 'lower'},
      );
    }
    final nextStage = attempt.stage + 1;
    final nextState = await _withSitting(ref, attempt);
    attempt = attempt.copyWith(
      stage: nextStage,
      stageStarted: false,
      currentIndex: 0,
      remainingSeconds: nextState.sitting.stages[nextStage].seconds,
    );
    await _persist(attempt);
    state = AsyncData(nextState.withAttempt(attempt));
  }

  /// Marks the paper, saves the result and feeds the topic tallies.
  Future<void> _finish(ExamState current) async {
    final result = current.result();
    final next = current.attempt.copyWith(
      finishedAt: ref.read(clockProvider).now(),
      score: scoreOf(result),
    );
    await _persist(next);
    await ref.read(practiceTallyProvider.notifier).recordAll(result.topics);
    state = AsyncData(current.withAttempt(next));
  }
}

final examProvider = AsyncNotifierProvider.autoDispose.family<ExamNotifier, ExamState, String>(
  ExamNotifier.new,
);
