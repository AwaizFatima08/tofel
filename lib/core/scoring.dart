import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/core/grading.dart';

/// Points earned out of points available.
class Tally {
  const Tally(this.correct, this.total);

  final int correct;
  final int total;

  /// Whole percent; 0 for an empty tally.
  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  double get share => total == 0 ? 0 : correct / total;

  Tally operator +(Tally other) => Tally(correct + other.correct, total + other.total);
}

class TopicScore {
  const TopicScore({required this.section, required this.topic, required this.tally});

  final String section;
  final String topic;
  final Tally tally;
}

/// A 1-6 band from a share of points, by thresholds (highest first).
double _band(double share, List<(double, double)> table, double floor) {
  for (final (atLeast, band) in table) {
    if (share >= atLeast) return band;
  }
  return floor;
}

/// Estimated Reading or Listening band (1-6 in half bands). As on the real test the lower module caps the
/// score near the top of B2 (4.5) and the upper module opens the C levels. ETS equates scores statistically;
/// these thresholds are practice estimates.
double adaptiveBand(Tally tally, {required bool upper}) => upper
    ? _band(tally.share, const [
        (0.94, 6),
        (0.87, 5.5),
        (0.78, 5),
        (0.68, 4.5),
        (0.58, 4),
        (0.48, 3.5),
      ], 3)
    : _band(tally.share, const [
        (0.86, 4.5),
        (0.74, 4),
        (0.62, 3.5),
        (0.5, 3),
        (0.4, 2.5),
        (0.3, 2),
        (0.18, 1.5),
      ], 1);

/// Estimated Writing or Speaking band from the share of rubric points.
double linearBand(Tally tally) => _band(tally.share, const [
  (0.95, 6),
  (0.88, 5.5),
  (0.8, 5),
  (0.7, 4.5),
  (0.6, 4),
  (0.5, 3.5),
  (0.4, 3),
  (0.3, 2.5),
  (0.2, 2),
  (0.1, 1.5),
], 1);

/// Average of the section bands rounded to the nearest half band (5.25 → 5.5, 5.125 → 5), as ETS reports it.
double overallBand(List<double> bands) {
  final mean = bands.reduce((a, b) => a + b) / bands.length;
  return (mean * 2 + 1e-9).roundToDouble() / 2;
}

/// Comparable 0-120 total: the midpoint of the 0-120 range ETS publishes for each overall band.
int comparableTotal(double band) => switch (band) {
  >= 6 => 117,
  >= 5.5 => 110,
  >= 5 => 101,
  >= 4.5 => 90,
  >= 4 => 79,
  >= 3.5 => 65,
  >= 3 => 51,
  >= 2.5 => 39,
  >= 2 => 29,
  >= 1.5 => 18,
  _ => 6,
};

/// The CEFR level a band is aligned to.
String cefrOf(double band) => switch (band) {
  >= 6 => 'C2',
  >= 5 => 'C1',
  >= 4 => 'B2',
  >= 3 => 'B1',
  >= 2 => 'A2',
  _ => 'A1',
};

String formatBand(double band) =>
    band == band.roundToDouble() ? band.toStringAsFixed(0) : band.toStringAsFixed(1);

/// One section's outcome.
class SectionResult {
  const SectionResult({
    required this.key,
    required this.points,
    this.router,
    this.module,
    this.upper,
    this.unrated = 0,
  });

  /// `reading`, `listening`, `writing` or `speaking`.
  final String key;
  final Tally points;

  /// Adaptive sections: points in the router and the second module, and which module was taken.
  final Tally? router;
  final Tally? module;
  final bool? upper;

  /// Writing and speaking tasks the candidate has not rated yet.
  final int unrated;

  bool get isAdaptive => upper != null;

  double get band => isAdaptive ? adaptiveBand(points, upper: upper!) : linearBand(points);
}

/// The outcome of a finished mock.
class MockResult {
  const MockResult({required this.sections, required this.topics});

  final Map<String, SectionResult> sections;

  /// Auto-scored topics, weakest first.
  final List<TopicScore> topics;

  bool get complete => sections.values.every((s) => s.unrated == 0);

  double get overall => overallBand([for (final s in sections.values) s.band]);
}

MockResult scoreSitting(Sitting sitting, Map<String, String> responses, Map<String, int> ratings) {
  final points = <String, Tally>{};
  final routers = <String, Tally>{};
  final modules = <String, Tally>{};
  final unrated = <String, int>{};
  final topics = <(String, String), Tally>{};
  for (final stage in sitting.stages) {
    for (final question in sitting.questionsOf(stage)) {
      final response = responses[question.id];
      final int earned;
      if (question.type.isAutoScored) {
        earned = autoPoints(question, response);
        final key = (question.section, question.topic);
        topics[key] = (topics[key] ?? const Tally(0, 0)) + Tally(earned, question.maxPoints);
      } else {
        final rating = ratings[question.id];
        final answered = Responses.isAnswered(question, response);
        if (answered && rating == null) unrated[stage.section] = (unrated[stage.section] ?? 0) + 1;
        earned = answered ? (rating ?? 0) : 0;
      }
      final tally = Tally(earned, question.maxPoints);
      points[stage.section] = (points[stage.section] ?? const Tally(0, 0)) + tally;
      if (stage.isRouter) {
        routers[stage.section] = (routers[stage.section] ?? const Tally(0, 0)) + tally;
      }
      if (stage.isModule) {
        modules[stage.section] = (modules[stage.section] ?? const Tally(0, 0)) + tally;
      }
    }
  }
  final sections = {
    for (final key in sectionKeys)
      key: SectionResult(
        key: key,
        points: points[key] ?? const Tally(0, 0),
        router: routers[key],
        module: modules[key],
        upper: routers.containsKey(key)
            ? sitting.stages.any((s) => s.section == key && s.part == 'upper')
            : null,
        unrated: unrated[key] ?? 0,
      ),
  };
  final topicScores = [
    for (final MapEntry(:key, :value) in topics.entries)
      TopicScore(section: key.$1, topic: key.$2, tally: value),
  ]..sort((a, b) => a.tally.percent.compareTo(b.tally.percent));
  return MockResult(sections: sections, topics: topicScores);
}

const sectionKeys = ['reading', 'listening', 'writing', 'speaking'];

/// Router points in an adaptive [section], which decide the second module.
int routerPoints(Sitting sitting, String section, Map<String, String> responses) {
  final stage = sitting.stages.firstWhere((s) => s.section == section && s.isRouter);
  return sitting.questionsOf(stage).fold(0, (sum, q) => sum + autoPoints(q, responses[q.id]));
}
