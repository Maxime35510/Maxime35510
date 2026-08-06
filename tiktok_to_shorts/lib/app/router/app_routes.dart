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
