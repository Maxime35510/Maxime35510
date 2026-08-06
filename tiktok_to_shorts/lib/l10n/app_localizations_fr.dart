// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Shortsmith';

  @override
  String get homeTitleLine1 => 'TikTok';

  @override
  String get homeTitleLine2 => 'YouTube';

  @override
  String get homeSubtitle =>
      'Transformez vos propres TikToks en métadonnées prêtes pour les Shorts.';

  @override
  String get importCardTitle => 'Importez votre propre vidéo TikTok';

  @override
  String get importCardBody =>
      'Collez le lien d\'un de vos TikToks, ou choisissez le fichier vidéo téléchargé depuis votre profil TikTok.';

  @override
  String get importVideoButton => 'Importer une vidéo';

  @override
  String get historySectionTitle => 'Historique';

  @override
  String get historyEmptyTitle => 'Rien pour le moment';

  @override
  String get historyEmptyBody =>
      'Les vidéos importées apparaîtront ici pour recopier leur SEO plus tard.';

  @override
  String get historySearchHint => 'Rechercher légendes, titres, hashtags';

  @override
  String get historySearchEmptyTitle => 'Aucun résultat';

  @override
  String get historySearchEmptyBody =>
      'Essayez une autre légende, un autre titre ou hashtag.';

  @override
  String historyItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidéos',
      one: '1 vidéo',
      zero: 'Aucune vidéo',
    );
    return '$_temp0';
  }

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionCopySeo => 'Copier le SEO';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionReset => 'Réinitialiser';

  @override
  String get actionPaste => 'Coller';

  @override
  String get actionClear => 'Effacer';

  @override
  String get deleteDialogTitle => 'Supprimer cette entrée ?';

  @override
  String get deleteDialogBody =>
      'L\'entrée est retirée de l\'historique. Le fichier vidéo enregistré n\'est pas supprimé.';

  @override
  String get deleteDialogConfirm => 'Supprimer';

  @override
  String get deletedSnack => 'Entrée supprimée';

  @override
  String get undoAction => 'Annuler';

  @override
  String get importScreenTitle => 'Import';

  @override
  String get importLinkLabel => 'Lien TikTok';

  @override
  String get importLinkHint => 'https://www.tiktok.com/@vous/video/...';

  @override
  String get importLinkHelper =>
      'Uniquement vos propres vidéos. Nous utilisons le point d\'accès public oEmbed de TikTok pour lire la légende et la miniature.';

  @override
  String get importFetchMetadata => 'Récupérer les infos';

  @override
  String get importPickFileLabel => 'Fichier vidéo';

  @override
  String get importPickFileButton => 'Choisir un fichier vidéo';

  @override
  String get importPickFileHelper =>
      'Facultatif. Choisissez le .mp4 téléchargé depuis votre profil TikTok pour le prévisualiser et l\'enregistrer.';

  @override
  String importFileSelected(String name) {
    return 'Sélectionné : $name';
  }

  @override
  String get importLoadingTitle => 'Lecture des informations';

  @override
  String get importLoadingBody => 'Cela ne prend qu\'un instant.';

  @override
  String get importStartOver => 'Recommencer';

  @override
  String get resultCaptionTitle => 'Légende';

  @override
  String get resultHashtagsTitle => 'Hashtags';

  @override
  String get resultAuthorTitle => 'Auteur';

  @override
  String get resultPreviewTitle => 'Aperçu vidéo';

  @override
  String get resultNoPreview =>
      'Choisissez le fichier vidéo pour l\'afficher ici.';

  @override
  String get resultNoCaption => 'Aucune légende trouvée pour cette vidéo.';

  @override
  String get actionSaveVideo => 'Enregistrer la vidéo';

  @override
  String get actionCopyCaption => 'Copier la légende';

  @override
  String get actionCopyHashtags => 'Copier les hashtags';

  @override
  String get actionCopyEverything => 'Tout copier';

  @override
  String get actionPrepareForYouTube => 'Préparer pour YouTube';

  @override
  String get prepareScreenTitle => 'Préparer pour YouTube';

  @override
  String get prepareIntro =>
      'Relisez et modifiez tout avant de publier. Les changements sont enregistrés dans l\'historique.';

  @override
  String get prepareTitleLabel => 'Titre';

  @override
  String get prepareDescriptionLabel => 'Description';

  @override
  String get prepareHashtagsLabel => 'Hashtags';

  @override
  String get prepareRegenerate => 'Régénérer';

  @override
  String prepareCharCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String prepareTitleTooLong(int max) {
    return 'Les titres YouTube sont limités à $max caractères.';
  }

  @override
  String get prepareEmptyTitle => 'Ajoutez un titre avant de copier.';

  @override
  String get prepareSavedSnack => 'Enregistré dans l\'historique';

  @override
  String get prepareRegeneratedSnack =>
      'Métadonnées régénérées à partir de la légende d\'origine';

  @override
  String get copiedSnack => 'Copié dans le presse-papiers';

  @override
  String get copiedTitleSnack => 'Titre copié';

  @override
  String get copiedDescriptionSnack => 'Description copiée';

  @override
  String get copiedHashtagsSnack => 'Hashtags copiés';

  @override
  String get copiedEverythingSnack => 'Titre, description et hashtags copiés';

  @override
  String get copyNothingToCopy => 'Il n\'y a rien à copier pour l\'instant';

  @override
  String get saveVideoTitle => 'Enregistrement de la vidéo';

  @override
  String saveVideoProgress(int percent) {
    return '$percent % copiés';
  }

  @override
  String get saveVideoSuccess => 'Vidéo enregistrée';

  @override
  String saveVideoSuccessBody(String path) {
    return 'Enregistrée dans $path';
  }

  @override
  String get saveVideoNoSource => 'Choisissez d\'abord un fichier vidéo.';

  @override
  String get detailScreenTitle => 'Détails';

  @override
  String get detailSourceLink => 'Ouvrir l\'original sur TikTok';

  @override
  String detailSavedOn(String date) {
    return 'Enregistré le $date';
  }

  @override
  String get detailNoVideoFile =>
      'Aucun fichier vidéo local pour cette entrée.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsSeo => 'Réglages SEO';

  @override
  String get settingsMaxHashtags => 'Hashtags maximum';

  @override
  String get settingsMaxHashtagsBody =>
      'Nombre de hashtags conservés lors de la génération.';

  @override
  String get settingsAppendShorts => 'Ajouter #shorts';

  @override
  String get settingsAppendShortsBody =>
      'Ajoute le hashtag #shorts aux métadonnées générées.';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsStorageFolder => 'Dossier de stockage';

  @override
  String get settingsStorageFolderBody =>
      'Emplacement d\'écriture des vidéos enregistrées.';

  @override
  String get settingsChangeFolder => 'Changer de dossier';

  @override
  String get settingsDeleteCache => 'Vider le cache';

  @override
  String get settingsDeleteCacheBody =>
      'Efface les miniatures en cache et les fichiers temporaires.';

  @override
  String settingsCacheCleared(String size) {
    return 'Cache vidé ($size libérés)';
  }

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Licences open source';

  @override
  String get settingsAboutBody =>
      'Shortsmith vous aide à réutiliser les vidéos que vous avez déjà publiées sur TikTok. L\'application ne télécharge jamais le contenu d\'autrui : les légendes et miniatures proviennent du point d\'accès public oEmbed de TikTok, et les fichiers vidéo de votre propre appareil.';

  @override
  String get errorTitle => 'Une erreur est survenue';

  @override
  String get errorNoInternet =>
      'Vous semblez hors ligne. Vérifiez votre connexion et réessayez.';

  @override
  String get errorTimeout =>
      'La requête a pris trop de temps. Veuillez réessayer.';

  @override
  String get errorInvalidLink => 'Ce lien ne ressemble pas à une vidéo TikTok.';

  @override
  String get errorNotFound =>
      'Vidéo introuvable. Elle est peut-être privée ou supprimée.';

  @override
  String get errorEmptyResponse =>
      'TikTok n\'a renvoyé aucune information pour ce lien.';

  @override
  String get errorRateLimited =>
      'Trop de requêtes. Patientez un instant et réessayez.';

  @override
  String get errorServer =>
      'TikTok ne répond pas pour le moment. Réessayez plus tard.';

  @override
  String get errorPermissionDenied =>
      'Permission refusée. Autorisez l\'accès au stockage pour enregistrer.';

  @override
  String get errorStorageFull =>
      'Espace de stockage insuffisant pour enregistrer cette vidéo.';

  @override
  String get errorFileMissing => 'Ce fichier n\'existe plus sur cet appareil.';

  @override
  String get errorStorage => 'Le fichier n\'a pas pu être enregistré.';

  @override
  String get errorCancelled => 'Annulé.';

  @override
  String get errorUnknown =>
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  String get openSettings => 'Ouvrir les paramètres';
}
