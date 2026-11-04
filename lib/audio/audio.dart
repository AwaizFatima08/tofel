import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:toefl_prep/content/models.dart';

/// Reads listening scripts and speaking prompts aloud. The phone's text-to-speech engine does the speaking,
/// so recordings work offline once an English voice is installed.
abstract interface class Speaker {
  /// Speaks [lines] in order, a woman's or a man's voice per line; completes when done or stopped.
  Future<void> say(List<Line> lines);

  Future<void> stop();
}

/// Records spoken answers and plays them back.
abstract interface class VoiceRecorder {
  /// Asks for the microphone if needed; false when the candidate refuses.
  Future<bool> allowed();

  /// Starts recording answer [key] (an attempt and question id); replaces an older recording.
  Future<void> start(String key);

  /// Stops recording; returns whether a file was saved.
  Future<bool> stop();

  Future<bool> has(String key);

  /// Plays recording [key]; completes when playback ends.
  Future<void> play(String key);

  Future<void> stopPlaying();

  /// Deletes every recording whose key starts with [prefix].
  Future<void> deleteAll(String prefix);
}

class TtsSpeaker implements Speaker {
  TtsSpeaker();

  final _tts = FlutterTts();
  Future<void>? _ready;
  Map<String, String>? _woman;
  Map<String, String>? _man;
  bool _stopped = false;

  // Google's offline US English voices, by gender (names are stable across engine versions).
  static const _womanVoices = ['sfg', 'tpf', 'iog', 'tpc', 'iob'];
  static const _manVoices = ['iom', 'iol', 'tpd'];

  Future<void> _setUp() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.47);
    try {
      final voices = [
        for (final voice in await _tts.getVoices as List<Object?>)
          (voice! as Map<Object?, Object?>).map((k, v) => MapEntry('$k', '$v')),
      ];
      Map<String, String>? pick(List<String> codes) {
        for (final code in codes) {
          for (final voice in voices) {
            final name = voice['name'] ?? '';
            if (name.startsWith('en-us-x-$code') && !name.contains('network')) {
              return {'name': name, 'locale': voice['locale'] ?? 'en-US'};
            }
          }
        }
        return null;
      }

      _woman = pick(_womanVoices);
      _man = pick(_manVoices);
    } on Object catch (error) {
      debugPrint('TTS voices unavailable: $error');
    }
  }

  Future<void> _use(Line line) async {
    final voice = line.isMan ? _man : _woman;
    if (voice != null) await _tts.setVoice(voice);
    // When the engine has one voice only, pitch tells the speakers apart.
    await _tts.setPitch(voice != null ? 1.0 : (line.isMan ? 0.82 : 1.12));
  }

  @override
  Future<void> say(List<Line> lines) async {
    await (_ready ??= _setUp());
    _stopped = false;
    for (final line in lines) {
      if (_stopped) return;
      await _use(line);
      // Some engines never report the end of speech (no audio output, engine crash): never wait forever.
      await _tts.speak(line.text).timeout(speechLimit(line.text), onTimeout: () => null);
      if (_stopped) return;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    await _tts.stop();
  }
}

class DeviceRecorder implements VoiceRecorder {
  DeviceRecorder();

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  String? _path;

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/recordings').create(recursive: true);
  }

  Future<File> _file(String key) async => File('${(await _dir()).path}/$key.m4a');

  @override
  Future<bool> allowed() => _recorder.hasPermission();

  @override
  Future<void> start(String key) async {
    final file = await _file(key);
    if (file.existsSync()) await file.delete();
    _path = file.path;
    await _recorder.start(const RecordConfig(numChannels: 1), path: file.path);
  }

  @override
  Future<bool> stop() async {
    if (!await _recorder.isRecording()) return false;
    final path = await _recorder.stop();
    return path != null && File(path).existsSync() && path == _path;
  }

  @override
  Future<bool> has(String key) async => (await _file(key)).existsSync();

  @override
  Future<void> play(String key) async {
    final file = await _file(key);
    if (!file.existsSync()) return;
    await _player.setFilePath(file.path);
    final done = _player.playerStateStream.firstWhere(
      (state) => state.processingState == ProcessingState.completed || !state.playing,
    );
    await _player.play();
    await done;
    await _player.stop();
  }

  @override
  Future<void> stopPlaying() => _player.stop();

  @override
  Future<void> deleteAll(String prefix) async {
    final dir = await _dir();
    for (final entity in dir.listSync()) {
      if (entity is File && entity.uri.pathSegments.last.startsWith(prefix)) await entity.delete();
    }
  }
}

/// Silent stand-ins for tests: speaking takes no time and recordings are remembered in memory.
class SilentSpeaker implements Speaker {
  final spoken = <String>[];

  @override
  Future<void> say(List<Line> lines) async => spoken.addAll([for (final line in lines) line.text]);

  @override
  Future<void> stop() async {}
}

class MemoryRecorder implements VoiceRecorder {
  final saved = <String>{};
  String? _current;

  @override
  Future<bool> allowed() async => true;

  @override
  Future<void> start(String key) async => _current = key;

  @override
  Future<bool> stop() async {
    if (_current == null) return false;
    saved.add(_current!);
    _current = null;
    return true;
  }

  @override
  Future<bool> has(String key) async => saved.contains(key);

  @override
  Future<void> play(String key) async {}

  @override
  Future<void> stopPlaying() async {}

  @override
  Future<void> deleteAll(String prefix) async => saved.removeWhere((key) => key.startsWith(prefix));
}

final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());

final recorderProvider = Provider<VoiceRecorder>((ref) => DeviceRecorder());

/// Recording key of a mock answer.
String recordingKey(String attemptId, String questionId) => '$attemptId-$questionId';

/// Recording key of a practice answer.
String practiceKey(String questionId) => 'practice-$questionId';

/// The longest a line may take to speak: about twice its normal length, at least 6 seconds.
Duration speechLimit(String text) {
  final words = text.split(RegExp(r'\s+')).length;
  return Duration(milliseconds: (words * 900 + 3000).clamp(6000, 240000));
}

/// Seconds to answer a Listen and Repeat sentence: longer sentences get more time, up to [longest].
int repeatSeconds(Question question, int longest) {
  final words = question.stem.split(RegExp(r'\s+')).length;
  return (4 + words * 0.55).round().clamp(6, longest);
}

/// The lines read aloud for a listening item: the script of its set, or a choose-a-response line.
List<Line> listeningLines(Question question, QuestionSet? set) =>
    set != null && set.isAudio ? set.script : [?question.spoken];
