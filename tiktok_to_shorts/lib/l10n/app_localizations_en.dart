// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Shortsmith';

  @override
  String get homeTitleLine1 => 'TikTok';

  @override
  String get homeTitleLine2 => 'YouTube';

  @override
  String get homeSubtitle =>
      'Turn your own TikToks into Shorts-ready metadata.';

  @override
  String get importCardTitle => 'Import your own TikTok video';

  @override
  String get importCardBody =>
      'Paste a link to one of your own TikToks, or pick the video file you downloaded from your TikTok profile.';

  @override
  String get importVideoButton => 'Import Video';

  @override
  String get historySectionTitle => 'History';

  @override
  String get historyEmptyTitle => 'Nothing here yet';

  @override
  String get historyEmptyBody =>
      'Imported videos will appear here so you can copy their SEO again later.';

  @override
  String get historySearchHint => 'Search captions, titles, hashtags';

  @override
  String get historySearchEmptyTitle => 'No matches';

  @override
  String get historySearchEmptyBody =>
      'Try a different caption, title or hashtag.';

  @override
  String historyItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'No videos',
    );
    return '$_temp0';
  }

  @override
  String get actionOpen => 'Open';

  @override
  String get actionCopySeo => 'Copy SEO';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDone => 'Done';

  @override
  String get actionClose => 'Close';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionClear => 'Clear';

  @override
  String get deleteDialogTitle => 'Delete this entry?';

  @override
  String get deleteDialogBody =>
      'This removes the entry from your history. The saved video file is not deleted.';

  @override
  String get deleteDialogConfirm => 'Delete';

  @override
  String get deletedSnack => 'Entry deleted';

  @override
  String get undoAction => 'Undo';

  @override
  String get importScreenTitle => 'Import';

  @override
  String get importLinkLabel => 'TikTok link';

  @override
  String get importLinkHint => 'https://www.tiktok.com/@you/video/...';

  @override
  String get importLinkHelper =>
      'Only your own videos. We use TikTok\'s public oEmbed endpoint to read the caption and thumbnail.';

  @override
  String get importFetchMetadata => 'Fetch details';

  @override
  String get importPickFileLabel => 'Video file';

  @override
  String get importPickFileButton => 'Choose video file';

  @override
  String get importPickFileHelper =>
      'Optional. Pick the .mp4 you downloaded from your own TikTok profile so you can preview and save it.';

  @override
  String importFileSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get importLoadingTitle => 'Reading video details';

  @override
  String get importLoadingBody => 'This only takes a moment.';

  @override
  String get importStartOver => 'Start over';

  @override
  String get resultCaptionTitle => 'Caption';

  @override
  String get resultHashtagsTitle => 'Hashtags';

  @override
  String get resultAuthorTitle => 'Author';

  @override
  String get resultPreviewTitle => 'Video preview';

  @override
  String get resultNoPreview => 'Pick the video file to preview it here.';

  @override
  String get resultNoCaption => 'No caption found for this video.';

  @override
  String get actionSaveVideo => 'Save Video';

  @override
  String get actionCopyCaption => 'Copy Caption';

  @override
  String get actionCopyHashtags => 'Copy Hashtags';

  @override
  String get actionCopyEverything => 'Copy Everything';

  @override
  String get actionPrepareForYouTube => 'Prepare for YouTube';

  @override
  String get prepareScreenTitle => 'Prepare for YouTube';

  @override
  String get prepareIntro =>
      'Review and edit anything before you publish. Changes are saved to your history.';

  @override
  String get prepareTitleLabel => 'Title';

  @override
  String get prepareDescriptionLabel => 'Description';

  @override
  String get prepareHashtagsLabel => 'Hashtags';

  @override
  String get prepareRegenerate => 'Regenerate';

  @override
  String prepareCharCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String prepareTitleTooLong(int max) {
    return 'YouTube titles are limited to $max characters.';
  }

  @override
  String get prepareEmptyTitle => 'Add a title before copying.';

  @override
  String get prepareSavedSnack => 'Saved to history';

  @override
  String get prepareRegeneratedSnack =>
      'Metadata regenerated from the original caption';

  @override
  String get copiedSnack => 'Copied to clipboard';

  @override
  String get copiedTitleSnack => 'Title copied';

  @override
  String get copiedDescriptionSnack => 'Description copied';

  @override
  String get copiedHashtagsSnack => 'Hashtags copied';

  @override
  String get copiedEverythingSnack => 'Title, description and hashtags copied';

  @override
  String get copyNothingToCopy => 'There is nothing to copy yet';

  @override
  String get saveVideoTitle => 'Saving video';

  @override
  String saveVideoProgress(int percent) {
    return '$percent% copied';
  }

  @override
  String get saveVideoSuccess => 'Video saved';

  @override
  String saveVideoSuccessBody(String path) {
    return 'Saved to $path';
  }

  @override
  String get saveVideoNoSource => 'Pick a video file first.';

  @override
  String get detailScreenTitle => 'Details';

  @override
  String get detailSourceLink => 'Open original on TikTok';

  @override
  String detailSavedOn(String date) {
    return 'Saved $date';
  }

  @override
  String get detailNoVideoFile => 'No local video file for this entry.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsSeo => 'SEO defaults';

  @override
  String get settingsMaxHashtags => 'Maximum hashtags';

  @override
  String get settingsMaxHashtagsBody =>
      'How many hashtags to keep when generating Shorts metadata.';

  @override
  String get settingsAppendShorts => 'Append #shorts';

  @override
  String get settingsAppendShortsBody =>
      'Adds the #shorts hashtag to generated metadata.';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsStorageFolder => 'Storage folder';

  @override
  String get settingsStorageFolderBody => 'Where saved videos are written.';

  @override
  String get settingsChangeFolder => 'Change folder';

  @override
  String get settingsDeleteCache => 'Delete cache';

  @override
  String get settingsDeleteCacheBody =>
      'Clears cached thumbnails and temporary files.';

  @override
  String settingsCacheCleared(String size) {
    return 'Cache cleared ($size freed)';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsAboutBody =>
      'Shortsmith helps you reuse the videos you already published on TikTok. It never downloads other people\'s content: captions and thumbnails come from TikTok\'s public oEmbed endpoint, and video files come from your own device.';

  @override
  String get aboutTitle => 'About';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyIntro =>
      'Shortsmith is built to stay out of your way. Here is exactly what it does with your data.';

  @override
  String get privacyLocalOnly =>
      'Everything stays on your device. Your history, settings and video files are stored locally and are never uploaded to any server.';

  @override
  String get privacyNoCredentials =>
      'No sign-in, ever. Shortsmith never asks for — and never stores — social-media passwords, cookies or session tokens.';

  @override
  String get privacyPublicMetadata =>
      'Only public details are read. Captions and thumbnails come from TikTok\'s public oEmbed endpoint; nothing private is accessed.';

  @override
  String get privacyOwnVideo =>
      'You bring your own video. Shortsmith does not download watermark-free videos. To preview or save a clip, pick the original file you exported from your own TikTok profile.';

  @override
  String get privacyLeastPermissions =>
      'Least privilege. The app uses the Android Storage Access Framework to open the files you choose, and requests no unnecessary permissions.';

  @override
  String get prepareVariantLabel => 'Style';

  @override
  String get prepareVariantSearch => 'Search';

  @override
  String get prepareVariantCatchy => 'Catchy';

  @override
  String get prepareVariantMinimal => 'Minimal';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorNoInternet =>
      'You appear to be offline. Check your connection and try again.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorInvalidLink => 'That does not look like a TikTok video link.';

  @override
  String get errorNotFound =>
      'That video could not be found. It may be private or deleted.';

  @override
  String get errorEmptyResponse => 'TikTok returned no details for that link.';

  @override
  String get errorRateLimited =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get errorServer =>
      'TikTok is not responding right now. Please try again later.';

  @override
  String get errorPermissionDenied =>
      'Permission denied. Grant storage access to save videos.';

  @override
  String get errorStorageFull => 'Not enough storage space to save this video.';

  @override
  String get errorFileMissing => 'That file no longer exists on this device.';

  @override
  String get errorStorage => 'The file could not be saved.';

  @override
  String get errorCancelled => 'Cancelled.';

  @override
  String get errorUnknown => 'An unexpected error occurred. Please try again.';

  @override
  String get openSettings => 'Open settings';
}
