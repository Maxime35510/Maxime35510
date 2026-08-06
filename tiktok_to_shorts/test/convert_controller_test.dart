import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/core/result/result.dart';
import 'package:shortsmith/features/convert/presentation/viewmodels/convert_controller.dart';
import 'package:shortsmith/features/platform/domain/entities/social_platform.dart';
import 'package:shortsmith/features/settings/domain/entities/app_settings.dart';
import 'package:shortsmith/features/settings/domain/repositories/settings_repository.dart';
import 'package:shortsmith/core/di/providers.dart';

final class _FakeSettings implements SettingsRepository {
  AppSettings _s = const AppSettings();
  @override
  AppSettings read() => _s;
  @override
  Future<Result<void>> write(AppSettings settings) async {
    _s = settings;
    return const Success(null);
  }
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(_FakeSettings())],
  );

  group('ConvertController', () {
    test('detecting a TikTok link defaults the destination to YouTube', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(convertControllerProvider.notifier);

      controller.setInput('https://www.tiktok.com/@me/video/123');
      controller.setSourceCaption('Building a miniature Ferrari #cars');

      final state = c.read(convertControllerProvider);
      expect(state.source, SocialPlatform.tiktok);
      expect(state.destination, SocialPlatform.youtubeShorts);
      expect(state.output?.hasTitle, isTrue);
    });

    test('switching the destination reshapes the output', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(convertControllerProvider.notifier);

      controller.setInput('https://www.tiktok.com/@me/video/123');
      controller.setSourceCaption('Building a miniature Ferrari #cars #asmr');
      controller.setDestination(SocialPlatform.instagramReels);

      final out = c.read(convertControllerProvider).output!;
      expect(out.destination, SocialPlatform.instagramReels);
      expect(out.hasCaption, isTrue);
      expect(out.title, isNull);
    });

    test('an invalid link produces no source and no output', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(convertControllerProvider.notifier);

      controller.setInput('https://vimeo.com/12345');
      controller.setSourceCaption('anything');

      final state = c.read(convertControllerProvider);
      expect(state.hasSource, isFalse);
      expect(state.output, isNull);
    });

    test('a manual source enables conversion without a link', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(convertControllerProvider.notifier);

      controller.setSource(SocialPlatform.instagramReels);
      controller.setSourceCaption('Building a miniature Ferrari #cars');

      final state = c.read(convertControllerProvider);
      expect(state.source, SocialPlatform.instagramReels);
      expect(state.destination, isNot(SocialPlatform.instagramReels));
      expect(state.output, isNotNull);
    });
  });
}
