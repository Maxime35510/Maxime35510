# Flutter's own rules are supplied by the Flutter Gradle plugin; these cover
# the plugins this app uses.

# --- video_player / ExoPlayer (Media3) ---------------------------------------
# Media3 resolves decoders and extractors reflectively, so R8 cannot see the
# references and would otherwise strip playback support.
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# --- Play Core (referenced by Flutter's deferred-components support) ----------
# Not used by this app, but the Flutter engine references it; without this R8
# fails the release build on missing classes.
-dontwarn com.google.android.play.core.**

# Keep annotations used for reflection by plugins.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
