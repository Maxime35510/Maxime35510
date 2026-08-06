import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Shortsmith'**
  String get appName;

  /// No description provided for @homeTitleLine1.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get homeTitleLine1;

  /// No description provided for @homeTitleLine2.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get homeTitleLine2;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn your own TikToks into Shorts-ready metadata.'**
  String get homeSubtitle;

  /// No description provided for @importCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Import your own TikTok video'**
  String get importCardTitle;

  /// No description provided for @importCardBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a link to one of your own TikToks, or pick the video file you downloaded from your TikTok profile.'**
  String get importCardBody;

  /// No description provided for @importVideoButton.
  ///
  /// In en, this message translates to:
  /// **'Import Video'**
  String get importVideoButton;

  /// No description provided for @historySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historySectionTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Imported videos will appear here so you can copy their SEO again later.'**
  String get historyEmptyBody;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search captions, titles, hashtags'**
  String get historySearchHint;

  /// No description provided for @historySearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get historySearchEmptyTitle;

  /// No description provided for @historySearchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different caption, title or hashtag.'**
  String get historySearchEmptyBody;

  /// No description provided for @historyItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No videos} =1{1 video} other{{count} videos}}'**
  String historyItemCount(int count);

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionCopySeo.
  ///
  /// In en, this message translates to:
  /// **'Copy SEO'**
  String get actionCopySeo;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the entry from your history. The saved video file is not deleted.'**
  String get deleteDialogBody;

  /// No description provided for @deleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDialogConfirm;

  /// No description provided for @deletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get deletedSnack;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @importScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importScreenTitle;

  /// No description provided for @importLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'TikTok link'**
  String get importLinkLabel;

  /// No description provided for @importLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.tiktok.com/@you/video/...'**
  String get importLinkHint;

  /// No description provided for @importLinkHelper.
  ///
  /// In en, this message translates to:
  /// **'Only your own videos. We use TikTok\'s public oEmbed endpoint to read the caption and thumbnail.'**
  String get importLinkHelper;

  /// No description provided for @importFetchMetadata.
  ///
  /// In en, this message translates to:
  /// **'Fetch details'**
  String get importFetchMetadata;

  /// No description provided for @importPickFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Video file'**
  String get importPickFileLabel;

  /// No description provided for @importPickFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose video file'**
  String get importPickFileButton;

  /// No description provided for @importPickFileHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Pick the .mp4 you downloaded from your own TikTok profile so you can preview and save it.'**
  String get importPickFileHelper;

  /// No description provided for @importFileSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String importFileSelected(String name);

  /// No description provided for @importLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading video details'**
  String get importLoadingTitle;

  /// No description provided for @importLoadingBody.
  ///
  /// In en, this message translates to:
  /// **'This only takes a moment.'**
  String get importLoadingBody;

  /// No description provided for @importStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get importStartOver;

  /// No description provided for @resultCaptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get resultCaptionTitle;

  /// No description provided for @resultHashtagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get resultHashtagsTitle;

  /// No description provided for @resultAuthorTitle.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get resultAuthorTitle;

  /// No description provided for @resultPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Video preview'**
  String get resultPreviewTitle;

  /// No description provided for @resultNoPreview.
  ///
  /// In en, this message translates to:
  /// **'Pick the video file to preview it here.'**
  String get resultNoPreview;

  /// No description provided for @resultNoCaption.
  ///
  /// In en, this message translates to:
  /// **'No caption found for this video.'**
  String get resultNoCaption;

  /// No description provided for @actionSaveVideo.
  ///
  /// In en, this message translates to:
  /// **'Save Video'**
  String get actionSaveVideo;

  /// No description provided for @actionCopyCaption.
  ///
  /// In en, this message translates to:
  /// **'Copy Caption'**
  String get actionCopyCaption;

  /// No description provided for @actionCopyHashtags.
  ///
  /// In en, this message translates to:
  /// **'Copy Hashtags'**
  String get actionCopyHashtags;

  /// No description provided for @actionCopyEverything.
  ///
  /// In en, this message translates to:
  /// **'Copy Everything'**
  String get actionCopyEverything;

  /// No description provided for @actionPrepareForYouTube.
  ///
  /// In en, this message translates to:
  /// **'Prepare for YouTube'**
  String get actionPrepareForYouTube;

  /// No description provided for @prepareScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare for YouTube'**
  String get prepareScreenTitle;

  /// No description provided for @prepareIntro.
  ///
  /// In en, this message translates to:
  /// **'Review and edit anything before you publish. Changes are saved to your history.'**
  String get prepareIntro;

  /// No description provided for @prepareTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get prepareTitleLabel;

  /// No description provided for @prepareDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get prepareDescriptionLabel;

  /// No description provided for @prepareHashtagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get prepareHashtagsLabel;

  /// No description provided for @prepareRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get prepareRegenerate;

  /// No description provided for @prepareCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String prepareCharCount(int count, int max);

  /// No description provided for @prepareTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'YouTube titles are limited to {max} characters.'**
  String prepareTitleTooLong(int max);

  /// No description provided for @prepareEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title before copying.'**
  String get prepareEmptyTitle;

  /// No description provided for @prepareSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved to history'**
  String get prepareSavedSnack;

  /// No description provided for @prepareRegeneratedSnack.
  ///
  /// In en, this message translates to:
  /// **'Metadata regenerated from the original caption'**
  String get prepareRegeneratedSnack;

  /// No description provided for @copiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedSnack;

  /// No description provided for @copiedTitleSnack.
  ///
  /// In en, this message translates to:
  /// **'Title copied'**
  String get copiedTitleSnack;

  /// No description provided for @copiedDescriptionSnack.
  ///
  /// In en, this message translates to:
  /// **'Description copied'**
  String get copiedDescriptionSnack;

  /// No description provided for @copiedHashtagsSnack.
  ///
  /// In en, this message translates to:
  /// **'Hashtags copied'**
  String get copiedHashtagsSnack;

  /// No description provided for @copiedEverythingSnack.
  ///
  /// In en, this message translates to:
  /// **'Title, description and hashtags copied'**
  String get copiedEverythingSnack;

  /// No description provided for @copyNothingToCopy.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to copy yet'**
  String get copyNothingToCopy;

  /// No description provided for @saveVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving video'**
  String get saveVideoTitle;

  /// No description provided for @saveVideoProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% copied'**
  String saveVideoProgress(int percent);

  /// No description provided for @saveVideoSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video saved'**
  String get saveVideoSuccess;

  /// No description provided for @saveVideoSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String saveVideoSuccessBody(String path);

  /// No description provided for @saveVideoNoSource.
  ///
  /// In en, this message translates to:
  /// **'Pick a video file first.'**
  String get saveVideoNoSource;

  /// No description provided for @detailScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailScreenTitle;

  /// No description provided for @detailSourceLink.
  ///
  /// In en, this message translates to:
  /// **'Open original on TikTok'**
  String get detailSourceLink;

  /// No description provided for @detailSavedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String detailSavedOn(String date);

  /// No description provided for @detailNoVideoFile.
  ///
  /// In en, this message translates to:
  /// **'No local video file for this entry.'**
  String get detailNoVideoFile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsSeo.
  ///
  /// In en, this message translates to:
  /// **'SEO defaults'**
  String get settingsSeo;

  /// No description provided for @settingsMaxHashtags.
  ///
  /// In en, this message translates to:
  /// **'Maximum hashtags'**
  String get settingsMaxHashtags;

  /// No description provided for @settingsMaxHashtagsBody.
  ///
  /// In en, this message translates to:
  /// **'How many hashtags to keep when generating Shorts metadata.'**
  String get settingsMaxHashtagsBody;

  /// No description provided for @settingsAppendShorts.
  ///
  /// In en, this message translates to:
  /// **'Append #shorts'**
  String get settingsAppendShorts;

  /// No description provided for @settingsAppendShortsBody.
  ///
  /// In en, this message translates to:
  /// **'Adds the #shorts hashtag to generated metadata.'**
  String get settingsAppendShortsBody;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsStorageFolder.
  ///
  /// In en, this message translates to:
  /// **'Storage folder'**
  String get settingsStorageFolder;

  /// No description provided for @settingsStorageFolderBody.
  ///
  /// In en, this message translates to:
  /// **'Where saved videos are written.'**
  String get settingsStorageFolderBody;

  /// No description provided for @settingsChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change folder'**
  String get settingsChangeFolder;

  /// No description provided for @settingsDeleteCache.
  ///
  /// In en, this message translates to:
  /// **'Delete cache'**
  String get settingsDeleteCache;

  /// No description provided for @settingsDeleteCacheBody.
  ///
  /// In en, this message translates to:
  /// **'Clears cached thumbnails and temporary files.'**
  String get settingsDeleteCacheBody;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared ({size} freed)'**
  String settingsCacheCleared(String size);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Shortsmith helps you reuse the videos you already published on TikTok. It never downloads other people\'s content: captions and thumbnails come from TikTok\'s public oEmbed endpoint, and video files come from your own device.'**
  String get settingsAboutBody;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Shortsmith is built to stay out of your way. Here is exactly what it does with your data.'**
  String get privacyIntro;

  /// No description provided for @privacyLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your device. Your history, settings and video files are stored locally and are never uploaded to any server.'**
  String get privacyLocalOnly;

  /// No description provided for @privacyNoCredentials.
  ///
  /// In en, this message translates to:
  /// **'No sign-in, ever. Shortsmith never asks for — and never stores — social-media passwords, cookies or session tokens.'**
  String get privacyNoCredentials;

  /// No description provided for @privacyPublicMetadata.
  ///
  /// In en, this message translates to:
  /// **'Only public details are read. Captions and thumbnails come from TikTok\'s public oEmbed endpoint; nothing private is accessed.'**
  String get privacyPublicMetadata;

  /// No description provided for @privacyOwnVideo.
  ///
  /// In en, this message translates to:
  /// **'You bring your own video. Shortsmith does not download watermark-free videos. To preview or save a clip, pick the original file you exported from your own TikTok profile.'**
  String get privacyOwnVideo;

  /// No description provided for @privacyLeastPermissions.
  ///
  /// In en, this message translates to:
  /// **'Least privilege. The app uses the Android Storage Access Framework to open the files you choose, and requests no unnecessary permissions.'**
  String get privacyLeastPermissions;

  /// No description provided for @prepareVariantLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get prepareVariantLabel;

  /// No description provided for @prepareVariantSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get prepareVariantSearch;

  /// No description provided for @prepareVariantCatchy.
  ///
  /// In en, this message translates to:
  /// **'Catchy'**
  String get prepareVariantCatchy;

  /// No description provided for @prepareVariantMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get prepareVariantMinimal;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a TikTok video link.'**
  String get errorInvalidLink;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That video could not be found. It may be private or deleted.'**
  String get errorNotFound;

  /// No description provided for @errorEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'TikTok returned no details for that link.'**
  String get errorEmptyResponse;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'TikTok is not responding right now. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Grant storage access to save videos.'**
  String get errorPermissionDenied;

  /// No description provided for @errorStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space to save this video.'**
  String get errorStorageFull;

  /// No description provided for @errorFileMissing.
  ///
  /// In en, this message translates to:
  /// **'That file no longer exists on this device.'**
  String get errorFileMissing;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'The file could not be saved.'**
  String get errorStorage;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnknown;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
