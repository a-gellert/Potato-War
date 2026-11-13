#!/bin/sh
# Command-line builds with the Defold install's bob (same engine as the editor).
#
#   sh tools/build.sh [playgama|poki|android|apk] [debug|release]
#
#   playgama  HTML5 for Playgama Bridge portals -> bundle/playgama/Great Potato War (+ .zip)
#   poki      HTML5 for Poki (tools/poki.settings)  -> bundle/poki/Great Potato War (+ .zip)
#   android   Google Play AAB (arm64 + armv7)        -> bundle/android/
#   apk       sideload APK for device testing (arm64) -> bundle/android-apk/
#
# Android release signing comes from the environment (never commit keys, see SECURITY.md):
#   ANDROID_KEYSTORE=/path/upload.keystore ANDROID_KEYSTORE_PASS=/path/pass.txt [ANDROID_KEY_PASS=/path/keypass.txt]
# Override the Defold location with DEFOLD=... (default: C:/Program Files (x86)/Defold).
set -e
TARGET=${1:-playgama}
VARIANT=${2:-release}
cd "$(dirname "$0")/.."

DEFOLD=${DEFOLD:-"C:/Program Files (x86)/Defold"}
[ -d "$DEFOLD" ] || DEFOLD="C:/Defold"
JAVA=$(ls -d "$DEFOLD"/packages/jdk-*/bin/java "$DEFOLD"/packages/jdk-*/bin/java.exe 2>/dev/null | head -1)
JAR=$(ls "$DEFOLD"/packages/defold-*.jar | head -1)
[ -n "$JAVA" ] && [ -n "$JAR" ] || { echo "Defold not found in $DEFOLD (set DEFOLD=...)"; exit 1; }

bob() { "$JAVA" -cp "$JAR" com.dynamo.bob.Bob --root . --variant "$VARIANT" --archive "$@"; }
# The build cache is shared between targets, so a target switch always starts clean
clean_build() { rm -rf build/default; }

case "$TARGET" in
	playgama)
		clean_build
		OUT=bundle/playgama
		bob --platform wasm-web --architectures wasm-web --bundle-output "$OUT" resolve build bundle
		;;
	poki)
		clean_build
		OUT=bundle/poki
		bob --settings tools/poki.settings --platform wasm-web --architectures wasm-web --bundle-output "$OUT" resolve build bundle
		;;
	android|apk)
		clean_build
		if [ "$TARGET" = android ]; then
			OUT=bundle/android; FORMAT=aab; ARCH=arm64-android,armv7-android
		else
			OUT=bundle/android-apk; FORMAT=apk; ARCH=arm64-android
		fi
		SIGN=""
		if [ -n "$ANDROID_KEYSTORE" ]; then
			SIGN="--keystore $ANDROID_KEYSTORE --keystore-pass $ANDROID_KEYSTORE_PASS"
			[ -n "$ANDROID_KEY_PASS" ] && SIGN="$SIGN --key-pass $ANDROID_KEY_PASS"
		elif [ "$VARIANT" = release ]; then
			echo "WARNING: no ANDROID_KEYSTORE set - the bundle is signed with a debug key and Google Play will reject it"
		fi
		# shellcheck disable=SC2086
		bob --platform arm64-android --architectures "$ARCH" --bundle-format "$FORMAT" $SIGN --bundle-output "$OUT" resolve build bundle
		;;
	*)
		echo "unknown target: $TARGET (playgama|poki|android|apk)"; exit 1 ;;
esac

# Portals take a zip with index.html at its root
if [ "$TARGET" = playgama ] || [ "$TARGET" = poki ]; then
	DIR="$OUT/Great Potato War"
	rm -f "$OUT/Great Potato War.zip"
	if command -v zip >/dev/null 2>&1; then
		(cd "$DIR" && zip -qr "../Great Potato War.zip" .)
	else
		powershell -NoProfile -Command "Compress-Archive -Path '$DIR/*' -DestinationPath '$OUT/Great Potato War.zip' -Force"
	fi
	echo "Upload: $OUT/Great Potato War.zip"
fi
echo "Done: $OUT"
