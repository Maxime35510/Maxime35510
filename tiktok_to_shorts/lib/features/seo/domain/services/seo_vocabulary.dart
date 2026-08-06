/// The rule tables that drive TikTok → YouTube metadata generation.
///
/// Keeping the vocabulary separate from the algorithm means the behaviour can
/// be tuned (or localised, or later swapped for a model-backed source) without
/// touching [SeoGenerator].
library;

/// Hashtags that exist purely to game the TikTok feed.
///
/// They carry no descriptive value on YouTube, where the same tags actively
/// look like spam, so they are dropped outright.
abstract final class PlatformNoiseTags {
  static const Set<String> values = {
    // Reach bait
    'fyp', 'fyp²', 'fypage', 'fypp', 'fy', 'foryou', 'foryoupage',
    'foryourpage', 'foryoupageofficial', 'parati', 'paratii', 'paratiii',
    'pourtoi', 'pourtoipage', 'neiperte', 'perte', 'perteee', 'xyzbca',
    'xybca', 'xyzabc', 'tiktokviral', 'viral', 'viralvideo', 'viralvideos',
    'viraltiktok', 'viralshort', 'viralshorts', 'trending', 'trend',
    'trendingnow', 'blowthisup', 'makethisviral', 'plsgoviral', 'plzviral',
    'goviral', 'boost', 'algorithm', 'unfreezemyaccount', 'unfrezzmyaccount',
    // Platform names / mechanics
    'tiktok', 'tiktokindia', 'tik', 'tok', 'duet', 'stitch', 'capcut',
    'greenscreen', 'greenscreenvideo', 'capcuttemplate', 'template',
    // Engagement CTAs
    'follow', 'followme', 'follow4follow', 'like', 'like4like',
    'likeforlike', 'likes', 'comment', 'share', 'subscribe', 'sub',
  };
}

/// Real words, but too broad to help discovery.
///
/// These are kept (they are not spam) but ranked last, so specific tags win
/// the limited hashtag budget.
abstract final class BroadTags {
  static const Set<String> values = {
    'love', 'funny', 'lol', 'cute', 'best', 'new', 'video', 'videos',
    'edit', 'edits', 'meme', 'memes', 'fun', 'amazing', 'wow', 'omg',
    'cool', 'life', 'daily', 'vibes', 'mood', 'nice', 'good', 'crazy',
    'insane', 'watch', 'short', 'shorts', 'reels', 'reel', 'explore',
  };
}

/// Filler openers creators put in front of the real caption.
///
/// Stripped before a title is derived so titles start on a real noun/verb.
abstract final class CaptionFillers {
  static const List<String> prefixes = [
    'pov:',
    'pov',
    'storytime:',
    'watch this',
    'watch till the end',
    'wait for it',
    'check out',
    'check this out',
    'look at this',
    'look at',
    'this is',
    'here is',
    "here's",
    'replying to',
    'reply to',
    'answer to',
  ];

  /// Matches "day 12 of ...", a very common TikTok opener.
  static final RegExp dayCounter = RegExp(
    r'^day\s+\d+\s+(of|de)\s+',
    caseSensitive: false,
  );
}

/// Words that stay lower-case in title case, unless first or last.
abstract final class TitleCaseSmallWords {
  static const Set<String> values = {
    'a', 'an', 'the', 'and', 'but', 'or', 'nor', 'for', 'so', 'yet',
    'at', 'by', 'in', 'of', 'on', 'to', 'up', 'as', 'vs', 'via',
    'with', 'from', 'into', 'over', 'than', 'that',
  };
}

/// Articles removed when a gerund opener is rewritten into a noun phrase.
abstract final class LeadingArticles {
  static const Set<String> values = {'a', 'an', 'the', 'my', 'this', 'some'};
}

/// Maps a gerund opener onto the noun that ends the rewritten title.
///
/// "Building a miniature Ferrari" → core "Miniature Ferrari" + noun "Assembly".
abstract final class GerundNouns {
  static const Map<String, String> values = {
    'building': 'Assembly',
    'assembling': 'Assembly',
    'making': 'Build',
    'crafting': 'Build',
    'creating': 'Build',
    'cooking': 'Recipe',
    'baking': 'Recipe',
    'preparing': 'Recipe',
    'painting': 'Paint Job',
    'drawing': 'Drawing',
    'sketching': 'Sketch',
    'restoring': 'Restoration',
    'refurbishing': 'Restoration',
    'cleaning': 'Deep Clean',
    'washing': 'Deep Clean',
    'unboxing': 'Unboxing',
    'opening': 'Unboxing',
    'fixing': 'Repair',
    'repairing': 'Repair',
    'installing': 'Install',
    'setting': 'Setup',
    'testing': 'Test',
    'reviewing': 'Review',
    'playing': 'Gameplay',
    'sewing': 'Sewing Project',
    'knitting': 'Knitting Project',
    'carving': 'Carving',
    'welding': 'Welding',
    'mixing': 'Mix',
    'editing': 'Edit',
    'training': 'Workout',
    'cutting': 'Cut',
    'growing': 'Grow',
    'organizing': 'Organisation',
    'organising': 'Organisation',
    'packing': 'Pack',
  };
}

/// A category inferred from the caption's hashtags and body.
///
/// Drives the title hook, the description opener and the description detail
/// line, so all three stay consistent with each other.
enum SeoCategory {
  asmr(
    keywords: {'asmr', 'satisfying', 'oddlysatisfying', 'relaxing'},
    hook: 'Satisfying Build',
    openerAdjective: 'satisfying',
    detail: 'Every detail is handcrafted.',
  ),
  craft(
    keywords: {
      'miniature', 'miniatures', 'diorama', 'diy', 'craft', 'crafts',
      'crafting', 'handmade', 'model', 'modelmaking', 'scalemodel',
      'woodworking', 'resin', 'clay', 'papercraft', 'lego',
    },
    hook: 'Handmade Build',
    openerAdjective: 'handmade',
    detail: 'Every detail is handcrafted.',
  ),
  cooking(
    keywords: {
      'cooking', 'recipe', 'recipes', 'food', 'foodie', 'baking', 'kitchen',
      'dessert', 'mealprep', 'homemade',
    },
    hook: 'Easy Recipe',
    openerAdjective: 'easy',
    detail: 'Simple ingredients, big flavour.',
  ),
  art(
    keywords: {
      'art', 'artist', 'drawing', 'painting', 'illustration', 'sketch',
      'digitalart', 'calligraphy', 'tattoo',
    },
    hook: 'Art Process',
    openerAdjective: 'full',
    detail: 'Start to finish, no shortcuts.',
  ),
  transformation(
    keywords: {
      'restoration', 'restore', 'transformation', 'makeover', 'renovation',
      'beforeandafter', 'glowup', 'repair',
    },
    hook: 'Before and After',
    openerAdjective: 'complete',
    detail: 'The full transformation, start to finish.',
  ),
  tutorial(
    keywords: {
      'tutorial', 'howto', 'diytutorial', 'guide', 'tips', 'tip',
      'lifehack', 'hack', 'hacks', 'learn',
    },
    hook: 'Step by Step',
    openerAdjective: 'step by step',
    detail: 'Follow along at your own pace.',
  ),
  review(
    keywords: {
      'review', 'unboxing', 'tech', 'gadget', 'gadgets', 'firstlook',
      'testing', 'comparison',
    },
    hook: 'Honest Review',
    openerAdjective: 'honest',
    detail: 'Everything worth knowing, in under a minute.',
  ),
  fitness(
    keywords: {
      'fitness', 'workout', 'gym', 'training', 'exercise', 'health',
      'calisthenics', 'running',
    },
    hook: 'Quick Workout',
    openerAdjective: 'quick',
    detail: 'Short session, real results.',
  ),
  gaming(
    keywords: {
      'gaming', 'gameplay', 'gamer', 'games', 'game', 'speedrun', 'clutch',
      'fps', 'minecraft', 'fortnite',
    },
    hook: 'Gameplay Highlights',
    openerAdjective: 'clean',
    detail: 'One clip, no cuts.',
  ),
  travel(
    keywords: {
      'travel', 'trip', 'roadtrip', 'adventure', 'vanlife', 'hiking',
      'wanderlust', 'explore',
    },
    hook: 'Travel Diary',
    openerAdjective: 'full',
    detail: 'Filmed on location.',
  ),
  automotive(
    keywords: {
      'cars', 'car', 'auto', 'automotive', 'supercar', 'jdm', 'motorbike',
      'moto', 'racing', 'ferrari', 'porsche',
    },
    hook: 'Full Build',
    openerAdjective: 'full',
    detail: 'Every detail matters on this one.',
  ),
  music(
    keywords: {
      'music', 'guitar', 'piano', 'drums', 'singing', 'cover', 'producer',
      'beat', 'studio',
    },
    hook: 'Live Take',
    openerAdjective: 'live',
    detail: 'Recorded in one take.',
  ),
  general(
    keywords: {},
    hook: 'Shorts',
    openerAdjective: '',
    detail: 'Filmed and edited by me.',
  );

  const SeoCategory({
    required this.keywords,
    required this.hook,
    required this.openerAdjective,
    required this.detail,
  });

  /// Hashtags/words that select this category.
  final Set<String> keywords;

  /// Appended after the title separator, e.g. `... | Satisfying Build`.
  final String hook;

  /// Slotted into `Watch this <adjective> <subject>.` — empty means omit.
  final String openerAdjective;

  /// Second line of the generated description.
  final String detail;

  /// Categories in priority order — the first match wins.
  ///
  /// [asmr] and [craft] outrank broader categories such as [automotive] so
  /// "#cars #miniature #asmr" is treated as a craft video, not a car video.
  static const List<SeoCategory> byPriority = [
    asmr,
    craft,
    transformation,
    cooking,
    art,
    tutorial,
    review,
    fitness,
    gaming,
    travel,
    music,
    automotive,
  ];
}
