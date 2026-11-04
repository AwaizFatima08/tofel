import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/ads/ad_service.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/ui/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _site = 'https://tofel.homilabs.org';

  void _open(String url) => unawaited(launchUrl(Uri.parse(url)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choicesRequired = ref.watch(privacyChoicesRequiredProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(l10n.appTitle, style: Theme.of(context).textTheme.titleLarge),
          Text(l10n.version),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.aboutBody),
          const SizedBox(height: AppSpacing.md),
          ListTile(title: Text(l10n.website), onTap: () => _open(_site)),
          ListTile(
            title: Text(l10n.privacy),
            onTap: () => _open('$_site/privacy.html'),
          ),
          if (choicesRequired)
            ListTile(
              title: Text(l10n.privacyChoices),
              onTap: () => unawaited(ref.read(adServiceProvider).showPrivacyChoices()),
            ),
          ListTile(
            title: Text(l10n.terms),
            onTap: () => _open('$_site/terms.html'),
          ),
          ListTile(title: Text(l10n.contact)),
        ],
      ),
    );
  }
}
