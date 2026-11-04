import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/features/results/task_rating.dart';
import 'package:toefl_prep/settings/settings_repository.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/audio_widgets.dart';
import 'package:toefl_prep/ui/question_view.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Practice one writing prompt (by question id) or one speaking set (by set id): do the task under the
/// real time limit, then compare with the model answer and rate yourself.
class TaskPracticeScreen extends ConsumerWidget {
  const TaskPracticeScreen({required this.section, required this.id, super.key});

  final String section;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
    value: ref.watch(bankProvider(section)),
    data: (bank) {
      final questions = [
        for (final question in bank.questions)
          if (question.id == id || question.setId == id) question,
      ];
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabPractice)),
        body: AsyncBody(
          value: ref.watch(catalogProvider),
          data: (catalog) => questions.first.type.isWriting
              ? _WritingPractice(
                  question: questions.first,
                  minutes: catalog.writingMinutes[questions.first.topic] ?? 10,
                )
              : _SpeakingPractice(
                  questions: questions,
                  set: bank.sets[id],
                  longest: catalog.speakingSeconds[questions.first.topic] ?? 45,
                ),
        ),
      );
    },
  );
}

class _WritingPractice extends ConsumerStatefulWidget {
  const _WritingPractice({required this.question, required this.minutes});

  final Question question;
  final int minutes;

  @override
  ConsumerState<_WritingPractice> createState() => _WritingPracticeState();
}

class _WritingPracticeState extends ConsumerState<_WritingPractice> {
  final _controller = TextEditingController();
  Timer? _timer;
  late int _left = widget.minutes * 60;
  bool _done = false;
  int? _rating;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _finish();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    _timer?.cancel();
    setState(() => _done = true);
  }

  Future<void> _rate(int value) async {
    final first = _rating == null;
    setState(() => _rating = value);
    if (first) {
      await ref
          .read(practiceTallyProvider.notifier)
          .record('writing', widget.question.topic, correct: value, total: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minutes = _left ~/ 60;
    final seconds = (_left % 60).toString().padLeft(2, '0');
    if (_done) {
      return ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          TaskRating(
            question: widget.question,
            set: null,
            response: _controller.text,
            recordKey: '',
            rating: _rating,
            onRate: (value) => unawaited(_rate(value)),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          l10n.timeLeftValue('$minutes:$seconds'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        WritingPrompt(question: widget.question),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          minLines: 10,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.wordCount(wordCount(_controller.text)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: _finish, child: Text(l10n.doneShowModel)),
      ],
    );
  }
}

class _SpeakingPractice extends ConsumerStatefulWidget {
  const _SpeakingPractice({required this.questions, required this.set, required this.longest});

  final List<Question> questions;
  final QuestionSet? set;
  final int longest;

  @override
  ConsumerState<_SpeakingPractice> createState() => _SpeakingPracticeState();
}

class _SpeakingPracticeState extends ConsumerState<_SpeakingPractice> {
  int _index = 0;
  bool _running = false;
  bool _answered = false;
  bool _micRefused = false;
  final _ratings = <String, int>{};

  Question get _question => widget.questions[_index];

  String get _voice => widget.set?.voice ?? 'W';

  Future<void> _rate(int value) async {
    final first = !_ratings.containsKey(_question.id);
    setState(() => _ratings[_question.id] = value);
    if (first) {
      await ref
          .read(practiceTallyProvider.notifier)
          .record('speaking', _question.topic, correct: value, total: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context).textTheme;
    final interview = _question.type == QuestionType.interview;
    final last = _index == widget.questions.length - 1;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        if (widget.set case final set?) ...[
          Text(set.title, style: theme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(set.text, style: const TextStyle(height: 1.45)),
          SayButton(lines: [Line(_voice, set.text)], label: l10n.hearScenario),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.questionOf(_index + 1, widget.questions.length), style: theme.labelLarge),
        const SizedBox(height: AppSpacing.md),
        if (_micRefused)
          Text(l10n.micRefused, style: const TextStyle(color: AppColors.incorrect))
        else if (_running)
          SpeakRunner(
            key: ValueKey('run-${_question.id}'),
            prompt: Line(_voice, _question.stem),
            recordKey: practiceKey(_question.id),
            seconds: interview ? widget.longest : repeatSeconds(_question, widget.longest),
            showPrompt: interview,
            onDone: (saved) => setState(() {
              _running = false;
              _answered = saved;
              _micRefused = !saved;
            }),
          )
        else if (!_answered)
          FilledButton.icon(
            onPressed: () => setState(() => _running = true),
            icon: const Icon(Icons.mic),
            label: Text(interview ? l10n.startQuestion : l10n.startSentence),
          )
        else ...[
          TaskRating(
            key: ValueKey('rate-${_question.id}'),
            question: _question,
            set: widget.set,
            response: Responses.recorded,
            recordKey: practiceKey(_question.id),
            rating: _ratings[_question.id],
            onRate: (value) => unawaited(_rate(value)),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => setState(() => _running = true),
            child: Text(l10n.tryAgain),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!last)
            FilledButton(
              onPressed: () => setState(() {
                _index++;
                _answered = false;
              }),
              child: Text(l10n.next),
            ),
        ],
      ],
    );
  }
}
