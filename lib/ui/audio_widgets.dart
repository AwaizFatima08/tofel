import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/ui/theme.dart';

/// A recording: the situation line, a speaker picture and the play state. In a mock it starts by itself
/// and plays once ([onDone] fires when it ends); in practice [replay] adds a Play again button.
class ListenPanel extends ConsumerStatefulWidget {
  const ListenPanel({
    required this.lines,
    this.situation,
    this.autoPlay = true,
    this.replay = false,
    this.onDone,
    super.key,
  });

  final List<Line> lines;
  final String? situation;
  final bool autoPlay;
  final bool replay;
  final VoidCallback? onDone;

  @override
  ConsumerState<ListenPanel> createState() => _ListenPanelState();
}

class _ListenPanelState extends ConsumerState<ListenPanel> {
  late final Speaker _speaker = ref.read(speakerProvider);
  bool _playing = false;
  bool _heard = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_play()));
  }

  @override
  void dispose() {
    if (_playing) unawaited(_speaker.stop());
    super.dispose();
  }

  Future<void> _play() async {
    if (_playing || !mounted) return;
    setState(() => _playing = true);
    await _speaker.say(widget.lines);
    if (!mounted) return;
    setState(() {
      _playing = false;
      _heard = true;
    });
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final voices = widget.lines.map((l) => l.voice).toSet();
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          children: [
            if (widget.situation case final text?) ...[
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final voice in voices)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        voice == 'M' ? Icons.face : Icons.face_3,
                        size: 34,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_playing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.nowPlaying),
            ] else if (_heard && !widget.replay)
              Text(l10n.recordingDone)
            else if (!widget.autoPlay || widget.replay)
              FilledButton.tonalIcon(
                onPressed: () => unawaited(_play()),
                icon: const Icon(Icons.volume_up),
                label: Text(_heard ? l10n.playAgain : l10n.play),
              ),
          ],
        ),
      ),
    );
  }
}

/// The stages of one speaking answer.
enum SpeakPhase { prompt, recording, done }

/// One speaking item: reads the prompt aloud, then records the answer for [seconds] with a countdown,
/// then calls [onDone]. Starts by itself.
class SpeakRunner extends ConsumerStatefulWidget {
  const SpeakRunner({
    required this.prompt,
    required this.recordKey,
    required this.seconds,
    required this.onDone,
    this.showPrompt = false,
    super.key,
  });

  /// What the speaker says (the sentence to repeat or the interviewer's question).
  final Line prompt;
  final String recordKey;
  final int seconds;
  final ValueChanged<bool> onDone;

  /// Interview questions are shown on screen as well; sentences to repeat are only heard.
  final bool showPrompt;

  @override
  ConsumerState<SpeakRunner> createState() => _SpeakRunnerState();
}

class _SpeakRunnerState extends ConsumerState<SpeakRunner> {
  late final Speaker _speaker = ref.read(speakerProvider);
  late final VoiceRecorder _recorder = ref.read(recorderProvider);
  SpeakPhase _phase = SpeakPhase.prompt;
  int _left = 0;
  Timer? _timer;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  void dispose() {
    _cancelled = true;
    _timer?.cancel();
    unawaited(_speaker.stop());
    if (_phase == SpeakPhase.recording) unawaited(_recorder.stop());
    super.dispose();
  }

  Future<void> _run() async {
    await _speaker.say([widget.prompt]);
    if (_cancelled || !mounted) return;
    final allowed = await _recorder.allowed();
    if (_cancelled || !mounted) return;
    if (!allowed) {
      setState(() => _phase = SpeakPhase.done);
      widget.onDone(false);
      return;
    }
    await _recorder.start(widget.recordKey);
    setState(() {
      _phase = SpeakPhase.recording;
      _left = widget.seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) unawaited(_finish());
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    if (_phase != SpeakPhase.recording) return;
    final saved = await _recorder.stop();
    if (!mounted) return;
    setState(() => _phase = SpeakPhase.done);
    widget.onDone(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            widget.prompt.isMan ? Icons.face : Icons.face_3,
            size: 40,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.showPrompt)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
            child: Text(widget.prompt.text, textAlign: TextAlign.center, style: theme.titleMedium),
          ),
        switch (_phase) {
          SpeakPhase.prompt => Column(
            children: [const LinearProgressIndicator(), Text(l10n.listenNow)],
          ),
          SpeakPhase.recording => Column(
            children: [
              Icon(
                Icons.mic,
                color: AppColors.incorrect,
                size: 40,
                semanticLabel: l10n.recordingNow,
              ),
              Text(l10n.speakNow, style: theme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(value: _left / widget.seconds),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.secondsLeft(_left)),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(onPressed: () => unawaited(_finish()), child: Text(l10n.doneSpeaking)),
            ],
          ),
          SpeakPhase.done => Text(l10n.answerSaved),
        },
      ],
    );
  }
}

/// Plays a saved answer back.
class PlaybackButton extends ConsumerStatefulWidget {
  const PlaybackButton({required this.recordKey, super.key});

  final String recordKey;

  @override
  ConsumerState<PlaybackButton> createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends ConsumerState<PlaybackButton> {
  late final VoiceRecorder _recorder = ref.read(recorderProvider);
  bool _playing = false;
  bool? _exists;

  @override
  void initState() {
    super.initState();
    unawaited(
      _recorder.has(widget.recordKey).then((has) {
        if (mounted) setState(() => _exists = has);
      }),
    );
  }

  @override
  void dispose() {
    if (_playing) unawaited(_recorder.stopPlaying());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _recorder.stopPlaying();
      return;
    }
    setState(() => _playing = true);
    await _recorder.play(widget.recordKey);
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_exists == false) {
      return Text(l10n.noRecording, style: Theme.of(context).textTheme.bodySmall);
    }
    return OutlinedButton.icon(
      onPressed: _exists == true ? () => unawaited(_toggle()) : null,
      icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
      label: Text(_playing ? l10n.stopPlaying : l10n.playMyAnswer),
    );
  }
}

/// Hears a line on demand (speaking review: the sentence or question again).
class SayButton extends ConsumerWidget {
  const SayButton({required this.lines, required this.label, super.key});

  final List<Line> lines;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    onPressed: () => unawaited(ref.read(speakerProvider).say(lines)),
    icon: const Icon(Icons.volume_up_outlined),
    label: Text(label),
  );
}
