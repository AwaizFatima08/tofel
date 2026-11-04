import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/ads/ad_service.dart';
import 'package:toefl_prep/ads/google_ad_service.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/core/clock.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) debugPrint('Unhandled Flutter error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };
  final ads = GoogleAdService(const SystemClock());
  runApp(
    ProviderScope(
      overrides: [adServiceProvider.overrideWithValue(ads)],
      child: const ToeflApp(),
    ),
  );
  unawaited(ads.start());
}
