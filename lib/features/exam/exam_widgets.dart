import 'package:flutter/material.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/features/exam/exam_notifier.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Clock text for a number of seconds, e.g. 1:59:30.
String formatClock(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final rest = seconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:${two(minutes)}:${two(rest)}' : '${two(minutes)}:${two(rest)}';
}

/// Title of a stage, e.g. "Reading · Module 2 · Upper".
/// During a mock [showRoute] is false: the real test does not say which module you were given.
String stageTitle(BuildContext context, Stage stage, {bool showRoute = true}) {
  final l10n = context.l10n;
  final section = sectionTitle(context, stage.section);
  return switch (stage.part) {
    'router' => l10n.moduleTitle(section, 1),
    'upper' when showRoute => '${l10n.moduleTitle(section, 2)} · ${l10n.routeUpper}',
    'lower' when showRoute => '${l10n.moduleTitle(section, 2)} · ${l10n.routeLower}',
    'upper' || 'lower' => l10n.moduleTitle(section, 2),
    'module' => l10n.moduleTitle(section, 2),
    _ => '$section · ${taskTitle(context, stage.part)}',
  };
}

/// Short title for the exam app bar, e.g. "Reading 1".
String stageShortTitle(BuildContext context, Stage stage) {
  final section = sectionTitle(context, stage.section);
  return switch (stage.part) {
    'router' => '$section 1',
    'upper' || 'lower' || 'module' => '$section 2',
    _ => taskTitle(context, stage.part),
  };
}

String sectionTitle(BuildContext context, String section) {
  final l10n = context.l10n;
  return switch (section) {
    'reading' => l10n.sectionReading,
    'listening' => l10n.sectionListening,
    'writing' => l10n.sectionWriting,
    _ => l10n.sectionSpeaking,
  };
}

String taskTitle(BuildContext context, String task) {
  final l10n = context.l10n;
  return switch (task) {
    'bas' => l10n.taskBas,
    'eml' => l10n.taskEmail,
    'dsc' => l10n.taskDiscussion,
    'lrp' => l10n.taskRepeat,
    _ => l10n.taskInterview,
  };
}

class TimerLabel extends StatefulWidget {
  const TimerLabel({required this.seconds, super.key});

  final int seconds;

  @override
  State<TimerLabel> createState() => _TimerLabelState();
}

/// The section clock; tap to hide or show it, as on the real test.
class _TimerLabelState extends State<TimerLabel> {
  static const _warnBelowSeconds = 300;
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final warn = widget.seconds < _warnBelowSeconds;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: InkWell(
        onTap: () => setState(() => _hidden = !_hidden),
        borderRadius: BorderRadius.circular(8),
        child: Semantics(
          label: context.l10n.timeLeft,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  _hidden && !warn ? Icons.visibility_off_outlined : Icons.timer_outlined,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                if (!_hidden || warn)
                  Text(
                    formatClock(widget.seconds),
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                      color: warn ? AppColors.amber : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExamBar extends StatelessWidget {
  const ExamBar({
    required this.exam,
    required this.onPrevious,
    required this.onNext,
    required this.onReview,
    required this.onEnd,
    super.key,
  });

  final ExamState exam;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReview;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final index = exam.attempt.currentIndex;
    final last = index == exam.questions.length - 1;
    // Listening runs forward only, as on the test: no going back and no review screen.
    final forwardOnly = exam.stage.isListening;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        child: Row(
          children: [
            if (!forwardOnly) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: index == 0 ? null : onPrevious,
                  child: Text(l10n.previous),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.grid_view, size: 18),
                label: Text(l10n.review),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: FilledButton(
                onPressed: last ? onEnd : onNext,
                child: Text(last ? l10n.endSection : l10n.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The module's review screen: every question with its status.
class QuestionPalette extends StatelessWidget {
  const QuestionPalette({
    required this.exam,
    required this.onPick,
    required this.onEnd,
    super.key,
  });

  final ExamState exam;
  final ValueChanged<int> onPick;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final questions = exam.questions;
    final answered = questions
        .where((q) => Responses.isAnswered(q, exam.attempt.responses[q.id]))
        .length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(
            stageTitle(context, exam.stage, showRoute: false),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(l10n.answeredOf(answered, questions.length)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              _Legend(colour: Theme.of(context).colorScheme.primary, label: l10n.answered),
              _Legend(colour: AppColors.flagged, label: l10n.marked, ring: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < questions.length; i++)
                _PaletteCell(exam: exam, index: i, onPick: onPick),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onEnd, child: Text(l10n.endSection)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colour, required this.label, this.ring = false});

  final Color colour;
  final String label;
  final bool ring;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ring ? null : colour,
          border: Border.all(color: colour, width: 3),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label),
    ],
  );
}

class _PaletteCell extends StatelessWidget {
  const _PaletteCell({required this.exam, required this.index, required this.onPick});

  final ExamState exam;
  final int index;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final question = exam.questions[index];
    final answered = Responses.isAnswered(question, exam.attempt.responses[question.id]);
    final flagged = exam.attempt.flagged.contains(question.id);
    final current = exam.attempt.currentIndex == index;
    return InkWell(
      onTap: () => onPick(index),
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: answered ? scheme.primary : null,
          border: Border.all(
            color: flagged ? AppColors.flagged : scheme.outline,
            width: flagged || current ? 3 : 1,
          ),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(color: answered ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}
