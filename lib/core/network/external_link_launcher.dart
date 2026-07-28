import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the platform's default external handler (browser or a
/// matching app). Best-effort: a broken/unhandleable link must never crash
/// a tap on a link icon, so failures are swallowed silently.
Future<void> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Best-effort — nothing more to do if the platform can't open it.
  }
}
