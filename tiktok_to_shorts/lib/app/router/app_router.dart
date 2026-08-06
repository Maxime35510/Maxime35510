import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/state_views.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/batch/presentation/screens/batch_screen.dart';
import '../../features/convert/presentation/screens/convert_screen.dart';
import '../../features/history/presentation/screens/entry_detail_screen.dart';
import '../../features/history/presentation/screens/projects_screen.dart';
import '../../features/home/presentation/screens/universal_home_screen.dart';
import '../../features/import/presentation/screens/import_screen.dart';
import '../../features/seo/presentation/screens/prepare_screen.dart';
import '../../features/settings/presentation/screens/privacy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../core/error/failure.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// Exposed as a provider so the router can read app state later (deep links,
/// redirects) without becoming a global singleton.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.homePath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const UniversalHomeScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.importPath.substring(1),
            name: AppRoutes.importName,
            builder: (context, state) => const ImportScreen(),
          ),
          GoRoute(
            path: AppRoutes.convertPath.substring(1),
            name: AppRoutes.convertName,
            builder: (context, state) => const ConvertScreen(),
          ),
          GoRoute(
            path: AppRoutes.projectsPath.substring(1),
            name: AppRoutes.projectsName,
            builder: (context, state) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.batchPath.substring(1),
                name: AppRoutes.batchName,
                builder: (context, state) => const BatchScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settingsPath.substring(1),
            name: AppRoutes.settingsName,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.aboutPath.substring(1),
            name: AppRoutes.aboutName,
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.privacyPath.substring(1),
            name: AppRoutes.privacyName,
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: AppRoutes.detailPath.substring(1),
            name: AppRoutes.detailName,
            builder: (context, state) => EntryDetailScreen(
              entryId: state.pathParameters[AppRoutes.entryIdParam]!,
            ),
            routes: [
              GoRoute(
                path: AppRoutes.preparePath,
                name: AppRoutes.prepareName,
                builder: (context, state) => PrepareScreen(
                  entryId: state.pathParameters[AppRoutes.entryIdParam]!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    // A malformed deep link should land somewhere friendly, not on a red
    // screen — this is the last line of the app's no-crash guarantee.
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: FailureView(
        failure: Failure(
          FailureKind.unknown,
          debugMessage: state.error?.toString(),
        ),
        onRetry: () => AppRoutes.goToHome(context),
      ),
    ),
  );
});

/// Standard back button used by the secondary screens.
class AppBackButton extends StatelessWidget {
  const AppBackButton({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed:
        onPressed ??
        () {
          if (context.canPop()) {
            context.pop();
          } else {
            AppRoutes.goToHome(context);
          }
        },
  );
}

/// Shown when a history entry referenced by a route no longer exists.
class MissingEntryView extends StatelessWidget {
  const MissingEntryView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const AppBackButton()),
    body: EmptyState(
      icon: Icons.search_off_rounded,
      title: context.l10n.historySearchEmptyTitle,
      message: context.l10n.historyEmptyBody,
      action: FilledButton(
        onPressed: () => AppRoutes.goToHome(context),
        child: Text(context.l10n.actionClose),
      ),
    ),
  );
}
