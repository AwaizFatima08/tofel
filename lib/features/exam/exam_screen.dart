import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/features/exam/exam_notifier.dart';
import 'package:toefl_prep/features/exam/exam_widgets.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/audio_widgets.dart';
import 'package:toefl_prep/ui/question_view.dart';
import 'package:toefl_prep/ui/theme.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({required this.attemptId, super.key});

  final String attemptId;

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> with WidgetsBindingObserver {
  ExamNotifier get _notifier => ref.read(examProvider(widget.attemptId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) unawaited(_notifier.pauseTimer());
    if (lifecycle == AppLifecycleState.resumed) _notifier.resumeTimer();
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveTitle),
        content: Text(l10n.leaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.stay)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.leave)),
        ],
      ),
    );
    if (leave != true) return;
    await _notifier.pauseTimer();
    if (mounted) context.pop();
  }

  Future<void> _confirmEnd(ExamState exam) async {
    final l10n = context.l10n;
    final unanswered = exam.questions
        .where((q) => !Responses.isAnswered(q, exam.attempt.responses[q.id]))
        .length;
    final end = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.isLastStage ? l10n.finishTitle : l10n.endSectionTitle),
        content: Text(
          [
            if (unanswered > 0) l10n.unansweredWarning(unanswered),
            l10n.endSectionBody,
          ].join('\n\n'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepWorking)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(exam.isLastStage ? l10n.finishTest : l10n.endSection),
          ),
        ],
      ),
    );
    if (end == true) await _notifier.endStage();
  }

  Future<void> _openReview(ExamState exam) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => QuestionPalette(
      exam: exam,
      onPick: (index) {
        Navigator.pop(context);
        unawaited(_notifier.goTo(index));
      },
      onEnd: () {
        Navigator.pop(context);
        unawaited(_confirmEnd(exam));
      },
    ),
  );

  /// The bottom bar is hidden while a recording plays (listening) and for essays and speaking.
  bool _showsBar(ExamState exam) {
    final stage = exam.stage;
    if (!exam.attempt.stageStarted || stage.isEssay || stage.isSpeaking) return false;
    if (stage.isListening) return exam.attempt.played.contains(exam.audioKey(exam.question));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = examProvider(widget.attemptId);
    ref.listen(provider, (previous, next) {
      if (next.value?.attempt.isFinished ?? false) {
        context.pushReplacement('/results/${widget.attemptId}');
      }
    });
    return AsyncValueView(
      value: ref.watch(provider),
      data: (exam) {
        final stage = exam.stage;
        final started = exam.attempt.stageStarted;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmLeave());
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(stageShortTitle(context, stage)),
              actions: [
                if (started && stage.isTimed) TimerLabel(seconds: exam.attempt.remainingSeconds),
              ],
            ),
            body: !started
                ? _StageIntro(exam: exam, onBegin: () => unawaited(_notifier.beginStage()))
                : switch (stage) {
                    Stage(isEssay: true) => _EssayBody(
                      key: ValueKey(exam.question.id),
                      exam: exam,
                      notifier: _notifier,
                      onEnd: () => unawaited(_confirmEnd(exam)),
                    ),
                    Stage(isSpeaking: true) => _SpeakingBody(
                      key: ValueKey('speak-${exam.attempt.stage}-${exam.attempt.currentIndex}'),
                      exam: exam,
                      notifier: _notifier,
                    ),
                    Stage(isListening: true)
                        when !exam.attempt.played.contains(exam.audioKey(exam.question)) =>
                      _ListenGate(
                        key: ValueKey('audio-${exam.audioKey(exam.question)}'),
                        exam: exam,
                        notifier: _notifier,
                      ),
                    _ => _QuestionBody(exam: exam, notifier: _notifier),
                  },
            bottomNavigationBar: _showsBar(exam)
                ? ExamBar(
                    exam: exam,
                    onPrevious: () => unawaited(_notifier.goTo(exam.attempt.currentIndex - 1)),
                    onNext: () => unawaited(_notifier.goTo(exam.attempt.currentIndex + 1)),
                    onReview: () => unawaited(_openReview(exam)),
                    onEnd: () => unawaited(_confirmEnd(exam)),
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// The screen before each stage: what comes, how long it takes, and the Begin button.
class _StageIntro extends StatelessWidget {
  const _StageIntro({required this.exam, required this.onBegin});

  final ExamState exam;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stage = exam.stage;
    final theme = Theme.of(context).textTheme;
    final rules = switch (stage.part) {
      'bas' => l10n.introBas,
      'eml' => l10n.introEmail,
      'dsc' => l10n.introDiscussion,
      'lrp' => l10n.introRepeat,
      'int' => l10n.introInterview,
      _ => stage.isListening ? l10n.introListening : l10n.introReading,
    };
    final points = exam.questions.fold(0, (sum, q) => sum + (q.type == QuestionType.ctw ? 10 : 1));
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      children: [
        Text(
          l10n.stageOf(exam.attempt.stage + 1, exam.sitting.stages.length),
          style: theme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(stageTitle(context, stage, showRoute: false), style: theme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          stage.isTimed
              ? l10n.stageSize(points, stage.seconds ~/ 60)
              : l10n.stageItems(exam.questions.length),
          style: theme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(rules, style: const TextStyle(height: 1.5)),
        if (stage.isRouter) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.introAdaptive, style: const TextStyle(height: 1.5)),
        ],
        if (stage.isListening || stage.isSpeaking) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.introSound, style: const TextStyle(height: 1.5)),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onBegin, child: Text(l10n.beginSection)),
      ],
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({required this.exam, required this.notifier});

  final ExamState exam;
  final ExamNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final question = exam.question;
    final response = exam.attempt.responses[question.id];
    final flagged = exam.attempt.flagged.contains(question.id);
    final l10n = context.l10n;
    final set = exam.setOf(question);
    void respond(String value) => unawaited(notifier.respond(value));
    return ListView(
      key: PageStorageKey(question.id),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.questionOf(exam.attempt.currentIndex + 1, exam.questions.length),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (!exam.stage.isListening)
              FilterChip(
                avatar: Icon(
                  flagged ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.flagged,
                ),
                label: Text(l10n.mark),
                selected: flagged,
                showCheckmark: false,
                onSelected: (_) => unawaited(notifier.toggleFlag()),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...questionBody(context, question, set, response, respond),
      ],
    );
  }
}

/// The task area of one question, for the exam and practice: text, prompt and answer controls.
List<Widget> questionBody(
  BuildContext context,
  Question question,
  QuestionSet? set,
  String? response,
  ValueChanged<String>? onChanged, {
  bool reveal = false,
}) {
  final theme = Theme.of(context).textTheme;
  final l10n = context.l10n;
  return switch (question.type) {
    QuestionType.ctw => [
      Text(l10n.ctwInstruction, style: theme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
      const SizedBox(height: AppSpacing.sm),
      CtwView(
        key: ValueKey('ctw-${question.id}-$reveal'),
        question: question,
        response: response,
        onChanged: onChanged,
        reveal: reveal,
      ),
    ],
    QuestionType.bas => [
      Text(l10n.basInstruction, style: theme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
      const SizedBox(height: AppSpacing.sm),
      BasView(question: question, response: response, onChanged: onChanged, reveal: reveal),
    ],
    _ => [
      if (set != null && !set.isAudio) SetPanel(key: ValueKey(question.setId), set: set),
      if (question.type == QuestionType.lcr)
        Text(l10n.lcrInstruction, style: theme.titleMedium)
      else
        Text(question.stem, style: theme.titleMedium?.copyWith(height: 1.45)),
      const SizedBox(height: AppSpacing.md),
      ChoiceList(question: question, response: response, onChanged: onChanged, reveal: reveal),
    ],
  };
}

/// Plays a listening recording once before its questions appear.
class _ListenGate extends StatelessWidget {
  const _ListenGate({required this.exam, required this.notifier, super.key});

  final ExamState exam;
  final ExamNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final question = exam.question;
    final set = exam.setOf(question);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          l10n.questionOf(exam.attempt.currentIndex + 1, exam.questions.length),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ListenPanel(
          lines: listeningLines(question, set),
          situation: set?.text ?? l10n.lcrSituation,
          onDone: () => unawaited(notifier.markPlayed(exam.audioKey(question))),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.listenOnce, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Write an Email or Academic Discussion: the prompt and a plain editor with a word count.
class _EssayBody extends StatefulWidget {
  const _EssayBody({required this.exam, required this.notifier, required this.onEnd, super.key});

  final ExamState exam;
  final ExamNotifier notifier;
  final VoidCallback onEnd;

  @override
  State<_EssayBody> createState() => _EssayBodyState();
}

class _EssayBodyState extends State<_EssayBody> {
  late final Question _task = widget.exam.question;
  late final _controller = TextEditingController(text: widget.exam.attempt.responses[_task.id]);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(widget.notifier.respondTo(_task.id, _controller.text));
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(seconds: 2),
      () => unawaited(widget.notifier.respondTo(_task.id, text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        WritingPrompt(question: _task),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          minLines: 10,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: _task.type == QuestionType.email ? l10n.emailHint : l10n.discussionHint,
          ),
          onChanged: _changed,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.wordCount(wordCount(_controller.text)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () async {
            await widget.notifier.respondTo(_task.id, _controller.text);
            widget.onEnd();
          },
          child: Text(widget.exam.isLastStage ? l10n.finishTest : l10n.endSection),
        ),
      ],
    );
  }
}

/// Speaking runs by itself: the scenario is read once, then each sentence or question is heard and the
/// answer recorded with a countdown, as on the test.
class _SpeakingBody extends ConsumerStatefulWidget {
  const _SpeakingBody({required this.exam, required this.notifier, super.key});

  final ExamState exam;
  final ExamNotifier notifier;

  @override
  ConsumerState<_SpeakingBody> createState() => _SpeakingBodyState();
}

class _SpeakingBodyState extends ConsumerState<_SpeakingBody> {
  late bool _scenarioHeard = widget.exam.attempt.currentIndex > 0;
  bool _micRefused = false;

  Question get _question => widget.exam.question;

  Future<void> _answered(bool saved) async {
    if (!saved) {
      setState(() => _micRefused = true);
      return;
    }
    await widget.notifier.respondTo(_question.id, Responses.recorded);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final exam = widget.exam;
    if (exam.attempt.currentIndex + 1 < exam.questions.length) {
      await widget.notifier.goTo(exam.attempt.currentIndex + 1);
    } else {
      await widget.notifier.endStage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exam = widget.exam;
    final set = exam.setOf(_question);
    final voice = set?.voice ?? 'W';
    final isInterview = _question.type == QuestionType.interview;
    final longest = exam.catalog.speakingSeconds[isInterview ? 'int' : 'lrp']!;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      children: [
        Text(
          l10n.questionOf(exam.attempt.currentIndex + 1, exam.questions.length),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (set != null) ...[
          Text(set.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(set.text, style: const TextStyle(height: 1.45)),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (_micRefused)
          Text(l10n.micRefused, style: const TextStyle(color: AppColors.incorrect))
        else if (!_scenarioHeard)
          ListenPanel(
            lines: [Line(voice, set?.text ?? '')],
            onDone: () => setState(() => _scenarioHeard = true),
          )
        else
          SpeakRunner(
            prompt: Line(voice, _question.stem),
            recordKey: recordingKey(exam.attempt.id, _question.id),
            seconds: isInterview ? longest : repeatSeconds(_question, longest),
            onDone: (saved) => unawaited(_answered(saved)),
          ),
      ],
    );
  }
}
