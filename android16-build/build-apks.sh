#!/usr/bin/env bash
set -euo pipefail
sdk="${ANDROID_HOME:?SDK ya preinstalado en GitHub requerido}"
ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK:-}}"
test -d "$ndk/toolchains/llvm/prebuilt/linux-x86_64"
tools="$sdk/build-tools/36.0.0"
jar="$sdk/platforms/android-36/android.jar"
test -x "$tools/aapt2"
test -f "$jar"
mkdir -p android16-work/probe/classes android16-work/probe/dex android16-work/evidence
javac -source 8 -target 8 -encoding UTF-8 -bootclasspath "$jar" -d android16-work/probe/classes android16-build/MainActivity.java
"$tools/d8" --min-api 26 --lib "$jar" --output android16-work/probe/dex $(find android16-work/probe/classes -name '*.class')
keytool -genkeypair -noprompt -keystore android16-work/probe/test.p12 -storetype PKCS12 -storepass android -keypass android -alias miao -keyalg RSA -keysize 2048 -validity 3650 -dname "CN=Mi Android Online Prueba"
for mode in arm64 arm32; do
 if [ "$mode" = arm64 ]; then abi=arm64-v8a;target=aarch64-linux-android26;else abi=armeabi-v7a;target=armv7a-linux-androideabi26;fi
 out="android16-work/probe/$mode"
 mkdir -p "$out/lib/$abi"
 "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/$target-clang" -shared -fPIC -O2 -Wl,-z,max-page-size=16384 android16-build/probe.c -o "$out/lib/$abi/libmiao_test.so"
 cat >"$out/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="cl.miao.nativeprobe.$mode" android:versionCode="1" android:versionName="1.0">
 <uses-sdk android:minSdkVersion="26" android:targetSdkVersion="36"/>
 <application android:label="Prueba $mode" android:extractNativeLibs="true" android:theme="@android:style/Theme.Material.Light.NoActionBar">
  <activity android:name="cl.miao.nativeprobe.MainActivity" android:exported="true">
   <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
  </activity>
 </application>
</manifest>
EOF
 "$tools/aapt2" link --manifest "$out/AndroidManifest.xml" -I "$jar" -o "$out/unsigned.apk"
 python3 - "$out" "$abi" <<'PY'
from pathlib import Path
import sys,zipfile
root=Path(sys.argv[1]);abi=sys.argv[2]
with zipfile.ZipFile(root/"unsigned.apk","a",compression=zipfile.ZIP_DEFLATED) as z:
 z.write("android16-work/probe/dex/classes.dex","classes.dex")
 z.write(root/"lib"/abi/"libmiao_test.so","lib/"+abi+"/libmiao_test.so")
PY
 "$tools/zipalign" -f 4 "$out/unsigned.apk" "$out/aligned.apk"
 "$tools/apksigner" sign --ks android16-work/probe/test.p12 --ks-pass pass:android --out "android16-work/evidence/native-probe-$mode.apk" "$out/aligned.apk"
 "$tools/apksigner" verify --verbose "android16-work/evidence/native-probe-$mode.apk"
done
cp android16-build/MainActivity.java android16-build/probe.c android16-work/evidence/
sha256sum android16-work/evidence/native-probe-*.apk >android16-work/evidence/native-probe-sha256.txt

# El puente estático se prueba dentro del invitado; no se publica este binario.
"$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang" -static -O2 -Wall -Wextra -Werror android16-build/serial-bridge.c -o android16-work/probe/miao-bridge-arm64
