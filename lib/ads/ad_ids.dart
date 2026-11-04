import 'package:flutter/foundation.dart';

/// AdMob identifiers. Debug builds always use Google's published test units
/// so a developer never clicks a live ad.
abstract final class AdIds {
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // Real units from the HomiLabs AdMob account (homilabs.smc@gmail.com); see config/admob.json.
  static const _liveBanner = 'ca-app-pub-2087846699268567/2750664601';
  static const _liveInterstitial = 'ca-app-pub-2087846699268567/7184558625';

  static String get banner => kReleaseMode ? _liveBanner : _testBanner;
  static String get interstitial => kReleaseMode ? _liveInterstitial : _testInterstitial;
}
