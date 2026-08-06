# ShortSmith — Universal Short-Form Repurposing Assistant

**One video. Every platform.** A personal productivity app for creators who
publish the **same clip** across TikTok, YouTube Shorts and Instagram Reels.
Paste a link, ShortSmith detects the platform, and rewrites the caption into
metadata tailored for whichever network you're publishing to next — then keeps
a local project history you can copy or export again later.

Built with Flutter, Material 3, Clean Architecture and Riverpod.

---

## What it does

`Import → Detect → Transform → Review → Export`

| Step | What happens |
|---|---|
| **Detect** | Paste a TikTok, YouTube Shorts or Instagram Reels link into one universal field. A secure detector recognises the platform (HTTPS-only, exact-host allow-list, deceptive-domain rejection) and normalises the URL. |
| **Adapt** | The destination defaults to the obvious other network, and you can switch to any of the other two. All six source→destination directions are supported. |
| **Transform** | Three destination-specific strategies build platform-shaped metadata: YouTube (title + description + hashtags), TikTok (caption + hashtags), Instagram (hook + caption + hashtags). Three tones — Search / Catchy / Minimal. |
| **Review** | Every field is editable, regenerable and copyable. Attach your own clean original video, preview it with safe-zone overlays, and read a pre-export checklist. |
| **Export** | Copy, share to the OS share sheet, save the video, export a complete package (`title.txt`, `caption.txt`, `metadata.json`, …) or a single ZIP. |
| **Projects & batch** | Every conversion is stored locally and searchable. Batch-convert many projects to one destination with controlled concurrency and failure isolation. |

### Presets & personalisation

Preferred/excluded hashtags, a custom capitalization dictionary (`asmr → ASMR`),
and eight starter presets (Miniature ASMR, Model Cars, Vehicle Build, Unboxing,
Construction Equipment, Satisfying, Educational, General Creator).

### How it stays within the rules

ShortSmith never downloads other people's content and never touches a private
API. TikTok captions are read through TikTok's documented public **oEmbed**
endpoint; for other platforms you paste or type the caption. Video files come
from **your own device**.

It does **not** download watermark-free videos: when only metadata is available
it asks you to attach your own clean original file. There is no account and no
login — the app never asks for, and never stores, social-media passwords,
cookies or session tokens, and it never scrapes private APIs or evades platform
protections. An in-app **Privacy** screen (Settings → Privacy) states this
plainly, and an **About** screen credits the author with their public links.
File access uses the Android **Storage Access Framework** via `file_selector`;
no unnecessary permissions are requested.

---

## The SEO engine

The core feature is a deterministic, offline transformation — no model calls, no
network, instant, and fully unit-tested.

**Input**

```
Building a miniature Ferrari 😍

#fyp #viral #cars #miniature #asmr
```

**Output**

```
Title
Miniature Ferrari Assembly | Satisfying Build

Description
Watch this satisfying miniature Ferrari assembly.

Every detail is handcrafted.

#asmr #miniature #cars
```

### Why it produces that

1. **Parse** — `CaptionParser` splits the caption into body text, hashtags and
   mentions, stripping emoji and URLs.
2. **Curate hashtags** — `HashtagCurator` drops TikTok reach-bait (`#fyp`,
   `#viral`, `#capcut`, …). The survivors are ranked *in reverse*: creators
   lead with broad reach tags and finish with the specific ones, so later tags
   are the descriptive ones — and YouTube only renders the first three above
   the title.
3. **Categorise** — hashtags and body words select an `SeoCategory` (ASMR,
   craft, cooking, gaming, …). The category drives the title hook, the
   description opener and its detail line, so all three agree with each other.
4. **Rewrite the title** — a gerund opener becomes a noun phrase:
   `Building a miniature Ferrari` → `Miniature Ferrari Assembly`. Proper nouns
   and acronyms are preserved (`Ferrari`, `ASMR`, `iPhone`); title case follows
   English editorial rules. YouTube's 100-character limit is enforced, dropping
   the hook before truncating the keywords.
5. **Write the description** — a category-aware opener plus one detail line.
   Short descriptions outperform keyword walls on Shorts.

Everything it produces is a starting point; the user can edit every field, and
**Regenerate** restores the generated version.

### Three tones (variants)

The same caption can be rendered in three fixed, deterministic tones, chosen on
the Prepare screen and re-generated instantly:

| Variant | Title | Description |
|---|---|---|
| **Search** (default) | `Miniature Ferrari Assembly \| Satisfying Build` — keyword-first | Two lines: opener + category detail |
| **Catchy** | `Satisfying Build: Miniature Ferrari Assembly` — hook leads | A punchier one-line opener + detail |
| **Minimal** | `Miniature Ferrari Assembly` — bare subject | One short line, nothing appended |

`Search` is the historical default and its output is unchanged. All three share
the same curated hashtags and respect YouTube's 100-character title limit.

Tuning lives in one file — `lib/features/seo/domain/services/seo_vocabulary.dart` —
separate from the algorithm, so the word lists can change without touching logic.

---

## Architecture

Clean Architecture with a feature-first layout. Dependencies point **inwards**:
presentation → domain ← data. The domain layer imports no Flutter, no Dio and
no Hive, which is why it is testable as plain Dart.

```
lib/
├── app/                        # Composition of the app shell
│   ├── app.dart                #   MaterialApp.router
│   ├── router/                 #   GoRouter + typed navigation helpers
│   └── theme/                  #   Colours, spacing, typography, ThemeData
├── core/                       # Cross-feature infrastructure
│   ├── constants/              #   Every magic number and storage key
│   ├── di/providers.dart       #   The composition root
│   ├── error/                  #   Exception → Failure → localised message
│   ├── extensions/             #   context.l10n, context.palette, …
│   ├── network/                #   Dio client + retry interceptor
│   ├── result/                 #   Result<T> = Success | ResultFailure
│   ├── services/               #   Clipboard, file picking, video storage
│   ├── utils/                  #   Text, dates, ids
│   └── widgets/                #   The shared component library
├── features/
│   ├── about/                  # About screen (author + links)
│   ├── batch/                  # Batch runner + multi-select batch screen
│   ├── convert/                # Universal convert flow (detect→transform→export)
│   ├── export/                 # Package builder, ZIP, validator, safe zones
│   ├── history/                # Projects store + Projects screen
│   ├── home/                   # Universal home + link detection UI
│   ├── import/                 # TikTok oEmbed data source (caption fetch)
│   ├── platform/               # SocialPlatform + secure LinkDetector
│   ├── seo/                    # The metadata engine (shared analysis)
│   ├── settings/               # Preferences + privacy screen
│   └── transform/              # Output strategies, presets, dictionary
└── l10n/                       # ARB files (en, fr) + generated delegates
```

Each feature follows the same three layers:

```
feature/
├── data/           datasources → models → repository implementation
├── domain/         entities, repository interfaces, pure services
└── presentation/   view models (MVVM), screens, widgets
```

### Patterns used and why

| Pattern | Where | Why |
|---|---|---|
| **Repository** | `TikTokRepository`, `HistoryRepository`, `SettingsRepository` | Interfaces live in `domain/`, implementations in `data/`. Features depend on the abstraction, never on Dio or Hive. |
| **MVVM** | `ImportController`, `PrepareController`, `SettingsController` | Riverpod `Notifier`s hold screen state; widgets only render and dispatch. |
| **Dependency injection** | `core/di/providers.dart` | One composition root. Nothing constructs its own dependencies, so any implementation can be replaced with `overrideWith` — which is exactly how the widget tests run without Hive. |
| **Result type** | `Result<T>` | Repositories return success-or-failure instead of throwing, so callers are forced by the type system to handle the failure path. |
| **Sealed failures** | `FailureKind` | The data layer never builds user-facing strings; it returns a kind, and `FailureLocalizer` maps it to a localised message with an exhaustive `switch`. Adding a kind without a message is a compile error. |
| **Theme extension** | `AppPalette` | Colours Material has no slot for are read from the theme, so no widget branches on `brightness`. |

### Error handling

`ErrorMapper` is the single choke point where `dart:io`, Dio and platform errors
stop propagating. Above the repositories, only `Failure` exists. Covered:
no internet, timeouts, invalid links, 404 / 429 / 5xx, empty responses,
permission denied, storage full, missing files, cancellation, and anything
unanticipated. Cancellations are silent — the user knows they pressed back.

---

## Getting started

### Requirements

- Flutter **3.44** or newer (stable) — Dart 3.12+
- JDK **17**
- Android SDK with platform 36 and build-tools 36

```bash
flutter --version
```

### Run

```bash
git clone <this-repo>
cd tiktok_to_shorts

flutter pub get
flutter run
```

Localisations are generated automatically by the Flutter tool from
`lib/l10n/*.arb`. To regenerate them by hand:

```bash
flutter gen-l10n
```

### Quality gates

```bash
flutter analyze     # must report "No issues found!"
flutter test        # 144 tests
```

---

## Building an APK

### Debug

```bash
flutter build apk --debug
```

### Release (signed with the debug key — works with no setup)

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk   (~60 MB, all ABIs)
```

### Release, split per ABI (recommended)

Roughly a third of the size per device:

```bash
flutter build apk --release --split-per-abi
# app-arm64-v8a-release.apk     ~22 MB   ← modern phones
# app-armeabi-v7a-release.apk   ~20 MB   ← older 32-bit phones
# app-x86_64-release.apk        ~23 MB   ← emulators
```

### App Bundle, for Play Store upload

```bash
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab
```

### Signing a release properly

1. Create a keystore:

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill
   it in:

   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

3. Build. `android/app/build.gradle.kts` picks the file up automatically and
   falls back to the debug key when it is absent — so a fresh clone still
   builds.

`android/key.properties` and `*.jks` are gitignored. Never commit them.

### Install on a device

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Release artifacts (`dist/`)

Prebuilt, checksummed release APKs live in `dist/`:

```
dist/
├── ShortSmith-universal-release.apk   # ~60 MB, all ABIs — install anywhere
├── apks/
│   ├── app-arm64-v8a-release.apk      # ~22 MB — modern phones
│   ├── app-armeabi-v7a-release.apk    # ~20 MB — older 32-bit phones
│   └── app-x86_64-release.apk         # ~23 MB — emulators
└── SHA256SUMS.txt                     # verify with: sha256sum -c SHA256SUMS.txt
```

These are signed with the debug key (no setup required) and are meant for
sideloading and testing, not Play Store upload — use an App Bundle and a real
upload key for that. Verify integrity from inside `dist/`:

```bash
cd dist && sha256sum -c SHA256SUMS.txt
```

---

## Android configuration

| Setting | Value |
|---|---|
| Application ID | `com.maxime35.shortsmith` |
| minSdk / targetSdk / compileSdk | Flutter defaults (24 / 36 / 36) |
| Permissions | `INTERNET`, `READ_MEDIA_VIDEO` (33+), `READ_EXTERNAL_STORAGE` (≤32) |
| R8 / resource shrinking | Enabled for release |

Saved videos go to the app's own external directory
(`Android/data/com.maxime35.shortsmith/files/Shortsmith`), which needs **no
runtime permission** on any supported Android version and is still visible in
file managers. File picking goes through the Storage Access Framework, which
also needs no permission. You can point saving at a different folder in
Settings.

> **`android.builtInKotlin` must stay `false`** in `android/gradle.properties`.
> The Flutter Gradle plugin applies the Kotlin Android Plugin to any plugin
> subproject that does not declare it, and AGP 9 rejects that combination when
> built-in Kotlin is enabled.

---

## Design

Inspired by Linear, Notion and Material 3.

- **Neutrals are hand-picked, accents are seeded.** `ColorScheme.fromSeed`
  tints greys toward the seed colour, which reads muddy in a content-heavy app;
  the surfaces are specified directly and only the accents are derived.
- **Depth comes from a hairline border**, not elevation shadows — Material's
  default shadows read heavy next to this typography.
- **Inter is bundled**, not fetched at runtime, so typography is identical
  offline and on first launch. It ships as a variable font, so `AppTypography`
  sets the `wght` axis alongside `fontWeight` in one place.
- **Display sizes carry negative tracking.** Large text at default tracking
  reads loose; tightening it is most of what makes a headline feel designed.
- **Motion is small and consistent** — 150/260/420 ms, one fade-through page
  transition, 12 px entrance offsets, a 45 ms list stagger. Cards scale to 0.97
  while pressed.
- Full **light and dark** themes are produced by the same function, so a
  component cannot look polished in one mode and neglected in the other.

Layout is responsive: content is capped at 720 logical pixels, so the app stays
readable on a tablet or unfolded device instead of stretching a paragraph
across the whole window. Text scaling is clamped to 0.9–1.3.

---

## Performance

- **Lazy lists** — the history is a `SliverList.separated`; only visible cards
  are laid out.
- **Cached thumbnails** — `cached_network_image` with `memCacheWidth` set to
  the display size, so a grid of thumbnails stays off the large-image path.
- **Scoped rebuilds** — `select()` on providers, so changing the storage folder
  does not rebuild the history list.
- **Debounced work** — search filtering (220 ms) and metadata writes (600 ms)
  are debounced; typing never blocks on I/O.
- **Synchronous startup reads** — preferences and the Hive box are opened once
  in `bootstrap()` and injected, so the first frame already has the right theme.
- **Streaming file copy** — videos are copied in 256 KB chunks with
  back-pressure, so a 500 MB file never lands in memory.

---

## Testing

```
test/
├── seo_generator_test.dart      # The engine, incl. the documented example
├── tiktok_url_parser_test.dart  # Link forms, share text, junk input
├── history_entry_test.dart      # Search, serialisation, oEmbed mapping
├── error_handling_test.dart     # Every FailureKind mapping, Result
└── home_screen_test.dart        # Widget tests with fake repositories
```

```bash
flutter test
flutter test --coverage
```

---

## Localisation

All user-facing strings live in `lib/l10n/app_en.arb` and `app_fr.arb` and are
reached through `context.l10n`. No screen contains a hardcoded string. Adding a
language means adding one ARB file.

---

## Licence

Inter is bundled under the SIL Open Font License — see `assets/fonts/OFL.txt`.
Third-party licences are listed in-app under
**Settings → About → Open source licenses**.
