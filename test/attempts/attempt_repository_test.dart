import 'package:flutter_test/flutter_test.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/attempts/attempt_repository.dart';
import 'package:toefl_prep/core/clock.dart';
import 'package:toefl_prep/core/result.dart';

class MemoryStore implements DocumentStore {
  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async => contents = value;
}

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 11, 2, 10);
}

void main() {
  test('an attempt survives a reload with its answers, flags and time', () async {
    final store = MemoryStore();
    final repository = AttemptRepository(store, FixedClock());
    final started = await repository.start(paperId: 'toefl-01', seconds: 7200);
    final attempt = (started as Ok<Attempt, StorageFailure>).value;
    await repository.update(
      attempt.id,
      (current) => current.copyWith(
        responses: {'q1': '2'},
        routes: {'reading': 'upper'},
        played: {'lc-ts001'},
        ratings: {'we-t0001': 4},
        flagged: {'q2'},
        remainingSeconds: 100,
        currentIndex: 7,
      ),
    );
    final reloaded = await AttemptRepository(store, FixedClock()).byId(attempt.id);
    expect(reloaded!.responses, {'q1': '2'});
    expect(reloaded.routes, {'reading': 'upper'});
    expect(reloaded.played, {'lc-ts001'});
    expect(reloaded.ratings, {'we-t0001': 4});
    expect(reloaded.flagged, {'q2'});
    expect(reloaded.remainingSeconds, 100);
    expect(reloaded.currentIndex, 7);
    expect(reloaded.isFinished, isFalse);
  });

  test('a new attempt gets the paper time in seconds', () async {
    final repository = AttemptRepository(MemoryStore(), FixedClock());
    await repository.start(paperId: 'toefl-01', seconds: 7200);
    final all = await repository.watchAll().first;
    expect(all.single.remainingSeconds, 7200);
    expect(all.single.stage, 0);
    expect(all.single.stageStarted, isFalse);
  });
}
