import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/clock.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/settings/settings_repository.dart';

@immutable
class PracticeKey {
  const PracticeKey(this.section, this.topic);

  final String section;
  final String topic;

  @override
  bool operator ==(Object other) =>
      other is PracticeKey && other.section == section && other.topic == topic;

  @override
  int get hashCode => Object.hash(section, topic);
}

class PracticeState {
  const PracticeState({
    required this.questions,
    required this.sets,
    this.index = 0,
    this.response,
    this.checked = false,
    this.correct = 0,
    this.finished = false,
  });

  final List<Question> questions;
  final Map<String, QuestionSet> sets;
  final int index;

  /// The current question's response so far.
  final String? response;

  /// Whether the current question has been checked (answer and explanation shown).
  final bool checked;

  /// Points earned so far.
  final int correct;
  final bool finished;

  Question get question => questions[index];

  /// Points available in the session (10 per Complete the Words paragraph).
  int get points => questions.fold(0, (sum, q) => sum + q.maxPoints);

  PracticeState copyWith({
    int? index,
    String? response,
    bool clearResponse = false,
    bool? checked,
    int? correct,
    bool? finished,
  }) => PracticeState(
    questions: questions,
    sets: sets,
    index: index ?? this.index,
    response: clearResponse ? null : (response ?? this.response),
    checked: checked ?? this.checked,
    correct: correct ?? this.correct,
    finished: finished ?? this.finished,
  );
}

/// Pure pick of a practice session: whole sets stay together and in order.
List<Question> pickPractice(List<Question> pool, int seed, {int size = 10}) {
  final groups = <String, List<Question>>{};
  for (final question in pool) {
    (groups[question.setId ?? question.id] ??= []).add(question);
  }
  final shuffled = groups.values.toList()..shuffle(Random(seed));
  final picked = <Question>[];
  for (final group in shuffled) {
    if (picked.length >= size) break;
    picked.addAll(group);
  }
  return picked;
}

/// Multiple-choice questions are checked on the first tap; typed and built answers need the Check button.
bool checksOnTap(Question question) => question.type.isChoice;

class PracticeNotifier extends AsyncNotifier<PracticeState> {
  PracticeNotifier(this.key);

  final PracticeKey key;

  @override
  Future<PracticeState> build() async {
    final bank = await ref.watch(contentRepositoryProvider).bank(key.section);
    final pool = [
      for (final question in bank.questions)
        if (question.isPractice && question.topic == key.topic) question,
    ];
    final seed = ref.read(clockProvider).now().millisecondsSinceEpoch;
    return PracticeState(questions: pickPractice(pool, seed), sets: bank.sets);
  }

  void respond(String response) {
    final current = state.value;
    if (current == null || current.checked) return;
    final next = current.copyWith(response: response);
    state = AsyncData(next);
    if (checksOnTap(current.question)) check();
  }

  void check() {
    final current = state.value;
    if (current == null ||
        current.checked ||
        !Responses.isAnswered(current.question, current.response)) {
      return;
    }
    final earned = autoPoints(current.question, current.response);
    state = AsyncData(current.copyWith(checked: true, correct: current.correct + earned));
  }

  Future<void> next() async {
    final current = state.value;
    if (current == null) return;
    final finished = current.index + 1 >= current.questions.length;
    if (finished) {
      await ref
          .read(practiceTallyProvider.notifier)
          .record(
            key.section,
            key.topic,
            correct: current.correct,
            total: current.points,
          );
    }
    state = AsyncData(
      current.copyWith(
        index: finished ? current.index : current.index + 1,
        clearResponse: true,
        checked: false,
        finished: finished,
      ),
    );
  }
}

final practiceProvider = AsyncNotifierProvider.autoDispose
    .family<PracticeNotifier, PracticeState, PracticeKey>(
      PracticeNotifier.new,
    );
