import 'package:flutter_test/flutter_test.dart';
import 'package:toefl_prep/features/practice/practice_notifier.dart';

import '../support.dart';

void main() {
  test('takes ten single questions', () {
    final pool = [for (var i = 0; i < 15; i++) question('q$i')];
    expect(pickPractice(pool, 1), hasLength(10));
  });

  test('keeps a set whole and in order', () {
    final pool = [for (var i = 0; i < 6; i++) question('r$i', setId: 's1')];
    expect(pickPractice(pool, 1).map((q) => q.id), ['r0', 'r1', 'r2', 'r3', 'r4', 'r5']);
  });

  test('copes with a small or empty pool', () {
    expect(pickPractice([question('a')], 1), hasLength(1));
    expect(pickPractice([], 1), isEmpty);
  });
}
