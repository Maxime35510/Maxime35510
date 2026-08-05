#!/usr/bin/env bash
# Builds tiktok-warmup.apk with the raw SDK tools (no Gradle / no AndroidX).
set -euo pipefail

cd "$(dirname "$0")"

SDK="${ANDROID_HOME:-$HOME/android-sdk}"
BT="$SDK/build-tools/35.0.0"
PLATFORM="$SDK/platforms/android-35/android.jar"
OUT="build"

for f in "$BT/aapt2" "$BT/d8" "$BT/zipalign" "$BT/apksigner" "$PLATFORM"; do
    [ -e "$f" ] || { echo "missing: $f"; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/gen" "$OUT/classes" "$OUT/dex"

echo "==> aapt2 compile"
"$BT/aapt2" compile --dir res -o "$OUT/res.zip"

echo "==> aapt2 link"
"$BT/aapt2" link \
    -o "$OUT/base.apk" \
    -I "$PLATFORM" \
    --manifest AndroidManifest.xml \
    --java "$OUT/gen" \
    --min-sdk-version 24 \
    --target-sdk-version 35 \
    "$OUT/res.zip"

echo "==> javac"
find src "$OUT/gen" -name '*.java' > "$OUT/sources.txt"
# No pipe here: a pipeline would mask javac's exit status and produce a dexless APK.
javac -nowarn -source 8 -target 8 \
    -bootclasspath "$PLATFORM" \
    -classpath "$PLATFORM" \
    -d "$OUT/classes" \
    @"$OUT/sources.txt"

echo "==> d8"
find "$OUT/classes" -name '*.class' > "$OUT/classes.txt"
"$BT/d8" --lib "$PLATFORM" --min-api 24 --output "$OUT/dex" @"$OUT/classes.txt"

echo "==> package"
cp "$OUT/base.apk" "$OUT/unsigned.apk"
( cd "$OUT/dex" && jar uf ../unsigned.apk classes.dex )

"$BT/zipalign" -f 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"

if [ ! -f keystore.jks ]; then
    echo "==> generating signing key"
    keytool -genkeypair -keystore keystore.jks -alias warmup \
        -storepass android -keypass android \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=warmup" >/dev/null 2>&1
fi

echo "==> apksigner"
"$BT/apksigner" sign \
    --ks keystore.jks --ks-pass pass:android --key-pass pass:android \
    --out tiktok-warmup.apk "$OUT/aligned.apk"

"$BT/apksigner" verify --print-certs tiktok-warmup.apk >/dev/null
echo
echo "built: $(pwd)/tiktok-warmup.apk  ($(du -h tiktok-warmup.apk | cut -f1))"
