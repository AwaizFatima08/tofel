import 'package:toefl_prep/content/models.dart';

/// Section bands saved when a mock is finished, and updated as the candidate rates writing and speaking.
class MockScore {
  const MockScore({
    required this.reading,
    required this.listening,
    required this.writing,
    required this.speaking,
    required this.overall,
    required this.complete,
  });

  factory MockScore.fromJson(Json json) => MockScore(
    reading: (json['r']! as num).toDouble(),
    listening: (json['l']! as num).toDouble(),
    writing: (json['w']! as num).toDouble(),
    speaking: (json['s']! as num).toDouble(),
    overall: (json['o']! as num).toDouble(),
    complete: json['c'] as bool? ?? false,
  );

  /// 1-6 in half bands.
  final double reading;
  final double listening;
  final double writing;
  final double speaking;
  final double overall;

  /// False while writing or speaking tasks are still unrated (those count as 0 until rated).
  final bool complete;

  Json toJson() => {
    'r': reading,
    'l': listening,
    'w': writing,
    's': speaking,
    'o': overall,
    'c': complete,
  };
}

/// One sitting of a mock test. Immutable; every change goes through the repository as a new value.
class Attempt {
  const Attempt({
    required this.id,
    required this.paperId,
    required this.startedAt,
    required this.remainingSeconds,
    this.stage = 0,
    this.stageStarted = false,
    this.responses = const {},
    this.flagged = const {},
    this.played = const {},
    this.ratings = const {},
    this.currentIndex = 0,
    this.routes = const {},
    this.finishedAt,
    this.score,
  });

  factory Attempt.fromJson(Json json) => Attempt(
    id: json['id']! as String,
    paperId: json['paperId']! as String,
    startedAt: DateTime.parse(json['startedAt']! as String),
    remainingSeconds: json['remaining']! as int,
    stage: json['stage']! as int,
    stageStarted: json['stageStarted'] as bool? ?? false,
    responses: (json['responses']! as Json).cast<String, String>(),
    flagged: (json['flagged']! as List<Object?>).cast<String>().toSet(),
    played: (json['played'] as List<Object?>? ?? const []).cast<String>().toSet(),
    ratings: (json['ratings'] as Json? ?? const {}).cast<String, int>(),
    currentIndex: json['index']! as int,
    routes: (json['routes']! as Json).cast<String, String>(),
    finishedAt: switch (json['finishedAt']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    score: switch (json['score']) {
      final Json value => MockScore.fromJson(value),
      _ => null,
    },
  );

  final String id;
  final String paperId;
  final DateTime startedAt;

  /// Seconds left in the current stage.
  final int remainingSeconds;

  /// Index of the current stage (see `buildStages`).
  final int stage;

  /// Whether the candidate has begun the current stage (its clock runs).
  final bool stageStarted;

  /// Question id to encoded response (see `Responses`).
  final Map<String, String> responses;
  final Set<String> flagged;

  /// Listening recordings (set or question ids) already heard: each plays once, as on the test.
  final Set<String> played;

  /// The candidate's 0-5 ratings of writing and speaking tasks, by question id.
  final Map<String, int> ratings;

  /// Question index within the current stage.
  final int currentIndex;

  /// Section key to `lower` or `upper`, decided when its router module ends.
  final Map<String, String> routes;
  final DateTime? finishedAt;
  final MockScore? score;

  bool get isFinished => finishedAt != null;

  Attempt copyWith({
    int? remainingSeconds,
    int? stage,
    bool? stageStarted,
    Map<String, String>? responses,
    Set<String>? flagged,
    Set<String>? played,
    Map<String, int>? ratings,
    int? currentIndex,
    Map<String, String>? routes,
    DateTime? finishedAt,
    MockScore? score,
  }) => Attempt(
    id: id,
    paperId: paperId,
    startedAt: startedAt,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    stage: stage ?? this.stage,
    stageStarted: stageStarted ?? this.stageStarted,
    responses: responses ?? this.responses,
    flagged: flagged ?? this.flagged,
    played: played ?? this.played,
    ratings: ratings ?? this.ratings,
    currentIndex: currentIndex ?? this.currentIndex,
    routes: routes ?? this.routes,
    finishedAt: finishedAt ?? this.finishedAt,
    score: score ?? this.score,
  );

  Json toJson() => {
    'id': id,
    'paperId': paperId,
    'startedAt': startedAt.toIso8601String(),
    'remaining': remainingSeconds,
    'stage': stage,
    'stageStarted': stageStarted,
    'responses': responses,
    'flagged': flagged.toList(),
    'played': played.toList(),
    'ratings': ratings,
    'index': currentIndex,
    'routes': routes,
    if (finishedAt case final finished?) 'finishedAt': finished.toIso8601String(),
    if (score case final value?) 'score': value.toJson(),
  };
}
