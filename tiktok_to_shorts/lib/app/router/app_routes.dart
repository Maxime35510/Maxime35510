import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route names, paths and typed navigation helpers.
///
/// Widgets navigate through these helpers rather than by writing path strings,
/// so a route change is a single edit and a typo is a compile error.
abstract final class AppRoutes {
  static const String homePath = '/';
  static const String homeName = 'home';

  static const String importPath = '/import';
  static const String importName = 'import';

  static const String settingsPath = '/settings';
  static const String settingsName = 'settings';

  static const String aboutPath = '/about';
  static const String aboutName = 'about';

  static const String privacyPath = '/privacy';
  static const String privacyName = 'privacy';

  static const String convertPath = '/convert';
  static const String convertName = 'convert';

  static const String projectsPath = '/projects';
  static const String projectsName = 'projects';

  static const String batchPath = '/batch';
  static const String batchName = 'batch';

  /// Detail screen for one history entry.
  static const String detailPath = '/entry/:id';
  static const String detailName = 'detail';

  /// Prepare-for-YouTube editor, nested under the entry it edits.
  static const String preparePath = 'prepare';
  static const String prepareName = 'prepare';

  /// Route parameter holding the history entry id.
  static const String entryIdParam = 'id';

  static void goToHome(BuildContext context) => context.goNamed(homeName);

  static void goToImport(BuildContext context) => context.pushNamed(importName);

  static void goToSettings(BuildContext context) =>
      context.pushNamed(settingsName);

  static void goToAbout(BuildContext context) => context.pushNamed(aboutName);

  static void goToPrivacy(BuildContext context) =>
      context.pushNamed(privacyName);

  static void goToConvert(BuildContext context) =>
      context.pushNamed(convertName);

  static void goToProjects(BuildContext context) =>
      context.pushNamed(projectsName);

  static void goToBatch(BuildContext context) => context.pushNamed(batchName);

  static void goToDetail(BuildContext context, String entryId) =>
      context.pushNamed(detailName, pathParameters: {entryIdParam: entryId});

  static void goToPrepare(BuildContext context, String entryId) =>
      context.pushNamed(prepareName, pathParameters: {entryIdParam: entryId});

  /// Replaces the import screen with the prepare editor, so backing out of
  /// Prepare returns to Home rather than to a stale import result.
  static void replaceWithPrepare(BuildContext context, String entryId) =>
      context.pushReplacementNamed(
        prepareName,
        pathParameters: {entryIdParam: entryId},
      );
}
