import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now". Injected so timers and history are testable.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
