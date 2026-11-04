import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/clock.dart';
import 'package:toefl_prep/core/result.dart';

/// Raw storage for a JSON document. Swapped for an in-memory fake in tests.
abstract interface class DocumentStore {
  Future<String?> read();
  Future<void> write(String contents);
}

class FileDocumentStore implements DocumentStore {
  const FileDocumentStore(this.name);

  final String name;

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$name');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(file.path); // atomic replace: never half-written
  }
}

/// The single write path for attempts: every change is persisted first,
/// then the new list is published to watchers.
class AttemptRepository {
  AttemptRepository(this._store, this._clock);

  final DocumentStore _store;
  final Clock _clock;
  final _controller = StreamController<List<Attempt>>.broadcast();
  List<Attempt>? _cache;

  Future<List<Attempt>> _all() async {
    if (_cache case final cached?) return cached;
    final raw = await _store.read();
    final decoded = raw == null ? const <Object?>[] : jsonDecode(raw) as List<Object?>;
    return _cache = [
      for (final item in decoded) Attempt.fromJson(item! as Json),
    ];
  }

  /// All attempts, newest first; re-emits after every saved change.
  Stream<List<Attempt>> watchAll() async* {
    yield await _all();
    yield* _controller.stream;
  }

  Future<Attempt?> byId(String id) async =>
      (await _all()).where((attempt) => attempt.id == id).firstOrNull;

  Future<Result<Attempt, StorageFailure>> start({
    required String paperId,
    required int seconds,
  }) async {
    final now = _clock.now();
    final attempt = Attempt(
      id: '${now.microsecondsSinceEpoch}',
      paperId: paperId,
      startedAt: now,
      remainingSeconds: seconds,
    );
    final saved = await _save([attempt, ...await _all()]);
    return switch (saved) {
      Ok() => Ok(attempt),
      Err(:final failure) => Err(failure),
    };
  }

  /// Applies [change] to attempt [id] and persists it.
  Future<Result<void, StorageFailure>> update(
    String id,
    Attempt Function(Attempt current) change,
  ) async {
    final all = await _all();
    final index = all.indexWhere((attempt) => attempt.id == id);
    if (index < 0) return Err(StorageFailure('not-found:$id'));
    return _save([...all]..[index] = change(all[index]));
  }

  Future<Result<void, StorageFailure>> delete(String id) async => _save([
    for (final attempt in await _all())
      if (attempt.id != id) attempt,
  ]);

  Future<Result<void, StorageFailure>> _save(List<Attempt> attempts) async {
    try {
      await _store.write(
        jsonEncode([for (final attempt in attempts) attempt.toJson()]),
      );
    } on FileSystemException catch (error) {
      return Err(StorageFailure('write', cause: error));
    }
    _cache = attempts;
    _controller.add(attempts);
    return const Ok(null);
  }
}

final attemptStoreProvider = Provider<DocumentStore>(
  (ref) => const FileDocumentStore('attempts.json'),
);

final attemptRepositoryProvider = Provider<AttemptRepository>(
  (ref) => AttemptRepository(
    ref.watch(attemptStoreProvider),
    ref.watch(clockProvider),
  ),
);

final attemptsProvider = StreamProvider<List<Attempt>>(
  (ref) => ref.watch(attemptRepositoryProvider).watchAll(),
);
