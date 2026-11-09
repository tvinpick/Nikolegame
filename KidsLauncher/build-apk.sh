#!/usr/bin/env bash
# Сборка debug APK без Android Gradle Plugin и без Android SDK от Google.
# Нужен, когда dl.google.com / maven.google.com недоступны.
#
# Инструменты: JDK 17+, aapt, dalvik-exchange (dx), zipalign, apksigner
#   (Ubuntu/Debian: apt-get install aapt dalvik-exchange zipalign apksigner)
# android.jar (API 27) берётся из Robolectric android-all 8.1.0 (Maven Central),
# Kotlin-компилятор — kotlin-compiler-embeddable (Maven Central).
#
# Результат: build-manual/KidsLauncher-debug.apk
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/app/src/main"
OUT="$HERE/build-manual"
CACHE="${KL_CACHE:-$HOME/.cache/kidslauncher-build}"

PKG="com.nikole.kidslauncher"
MIN_SDK=26
TARGET_SDK=27
VERSION_CODE=1
VERSION_NAME="1.0"
KOTLIN=2.0.21
ANDROID_ALL="8.1.0-robolectric-4611349"
M2="https://repo.maven.apache.org/maven2"

mkdir -p "$CACHE"
fetch() { # $1 = путь в Maven-репозитории
  local f="$CACHE/$(basename "$1")"
  if [ ! -s "$f" ]; then
    echo "  загрузка $(basename "$1")"
    for i in 1 2 3 4 5; do
      curl -sSf -o "$f.part" "$M2/$1" && mv "$f.part" "$f" && break
      sleep $((i * 3))
    done
    [ -s "$f" ] || { echo "Не удалось скачать $1" >&2; exit 1; }
  fi
}

echo "== Зависимости"
fetch "org/robolectric/android-all/$ANDROID_ALL/android-all-$ANDROID_ALL.jar"
for a in kotlin-compiler-embeddable kotlin-stdlib kotlin-script-runtime kotlin-daemon-embeddable; do
  fetch "org/jetbrains/kotlin/$a/$KOTLIN/$a-$KOTLIN.jar"
done
fetch "org/jetbrains/kotlin/kotlin-reflect/1.6.10/kotlin-reflect-1.6.10.jar"
fetch "org/jetbrains/intellij/deps/trove4j/1.0.20200330/trove4j-1.0.20200330.jar"
fetch "org/jetbrains/annotations/13.0/annotations-13.0.jar"
fetch "org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.6.4/kotlinx-coroutines-core-jvm-1.6.4.jar"

ANDROID_JAR="$CACHE/android-all-$ANDROID_ALL.jar"
STDLIB="$CACHE/kotlin-stdlib-$KOTLIN.jar"
KOTLINC_CP="$CACHE/kotlin-compiler-embeddable-$KOTLIN.jar:$STDLIB:$CACHE/kotlin-script-runtime-$KOTLIN.jar:$CACHE/kotlin-daemon-embeddable-$KOTLIN.jar:$CACHE/kotlin-reflect-1.6.10.jar:$CACHE/trove4j-1.0.20200330.jar:$CACHE/annotations-13.0.jar:$CACHE/kotlinx-coroutines-core-jvm-1.6.4.jar"

rm -rf "$OUT"
mkdir -p "$OUT/gen" "$OUT/classes" "$OUT/dex" "$OUT/stdlib"

echo "== Ресурсы (aapt)"
# В исходном манифесте нет package (его задаёт namespace в Gradle) — добавляем.
sed "s|<manifest |<manifest package=\"$PKG\" |" "$APP/AndroidManifest.xml" > "$OUT/AndroidManifest.xml"
aapt package -f -m \
  -M "$OUT/AndroidManifest.xml" \
  -S "$APP/res" \
  -I "$ANDROID_JAR" \
  -J "$OUT/gen" \
  --min-sdk-version $MIN_SDK --target-sdk-version $TARGET_SDK \
  --version-code $VERSION_CODE --version-name $VERSION_NAME \
  -F "$OUT/resources.ap_"

echo "== Компиляция R.java"
javac --release 8 -nowarn -d "$OUT/classes" $(find "$OUT/gen" -name '*.java')

echo "== Компиляция Kotlin"
java -Xmx1g -cp "$KOTLINC_CP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
  -no-reflect -no-stdlib \
  -classpath "$ANDROID_JAR:$STDLIB:$OUT/classes" \
  -jvm-target 1.8 -Xlambdas=class -Xsam-conversions=class \
  -d "$OUT/classes" \
  $(find "$APP/java" -name '*.kt')

echo "== DEX (dx)"
# Из stdlib убираем module-info и multi-release-классы — dx их не понимает.
(cd "$OUT/stdlib" && unzip -qo "$STDLIB" -x 'META-INF/*' 'module-info.class')
dalvik-exchange --dex --min-sdk-version=$MIN_SDK --output="$OUT/dex/classes.dex" \
  "$OUT/classes" "$OUT/stdlib"

echo "== Упаковка APK"
cp "$OUT/resources.ap_" "$OUT/unsigned.apk"
(cd "$OUT/dex" && zip -q "$OUT/unsigned.apk" classes.dex)
zipalign -f 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"

KS="$HERE/debug.keystore"
if [ ! -f "$KS" ]; then
  keytool -genkeypair -keystore "$KS" -storepass android -keypass android \
    -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 10000 >/dev/null 2>&1
fi
apksigner sign --ks "$KS" --ks-pass pass:android --key-pass pass:android \
  --ks-key-alias androiddebugkey --min-sdk-version $MIN_SDK \
  --out "$OUT/KidsLauncher-debug.apk" "$OUT/aligned.apk"
apksigner verify "$OUT/KidsLauncher-debug.apk"

echo "Готово: $OUT/KidsLauncher-debug.apk ($(du -h "$OUT/KidsLauncher-debug.apk" | cut -f1))"
