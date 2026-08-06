import 'package:share_plus/share_plus.dart';

/// Wraps the OS share sheet so the rest of the app depends on an interface, not
/// on `share_plus` directly (and so tests can stub it).
///
/// It shares text or files through Android's `ACTION_SEND` — which needs no
/// storage permission — and never touches the user's original files beyond
/// handing their paths to the system.
abstract interface class ShareService {
  Future<void> shareText(String text, {String? subject});

  Future<void> shareFiles(List<String> paths, {String? text});
}

final class PlatformShareService implements ShareService {
  const PlatformShareService();

  @override
  Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  @override
  Future<void> shareFiles(List<String> paths, {String? text}) => SharePlus
      .instance
      .share(ShareParams(text: text, files: [for (final p in paths) XFile(p)]));
}
