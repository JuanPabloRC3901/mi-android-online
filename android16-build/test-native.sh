#!/usr/bin/env bash
set -euo pipefail
mkdir -p android16-work/rootfs android16-work/evidence android16-work/kernel android16-work/control
digest=sha256:0d774872e66ba99306c3e21172b251485bbb794cfb8f8e754add99d3e75f050e
docker pull --platform linux/arm64 "redroid/redroid@$digest"
container="miao-android16-inspect-$GITHUB_RUN_ID"
docker create --platform linux/arm64 --name "$container" "redroid/redroid@$digest" >/dev/null
docker export "$container" | sudo tar -xf - -C android16-work/rootfs
docker rm "$container" >/dev/null
sudo python3 android16-build/inspect.py
sudo chown "$(id -u):$(id -g)" android16-work/evidence/image-inspection.json
# El sistema de upstream sólo se usa para esta prueba privada efímera, no se publica como asset.
truncate -s 6G android16-work/root.ext4
sudo mke2fs -q -t ext4 -F -d android16-work/rootfs -L MIAO_ANDROID16 android16-work/root.ext4
kernel_tag="mi-android-arm64-${KERNEL_RUN_ID}-1-kernel"
for attempt in $(seq 1 60); do
 if gh release download "$kernel_tag" --repo "$GITHUB_REPOSITORY" --pattern arm64-kernel.tar.gz --dir android16-work/kernel; then break; fi
 if [ "$attempt" = 60 ]; then exit 1; fi
 sleep 20
done
tar -xzf android16-work/kernel/arm64-kernel.tar.gz -C android16-work/kernel
aarch64-linux-gnu-gcc -Os -ffreestanding -fno-builtin -fno-stack-protector -nostdlib -static -Wl,--build-id=none -Wl,-e,_start android16-build/init-android.c -o android16-work/control/init64
cp android16-work/kernel/arm64-kernel/arm32-probe android16-work/control/arm32-probe
python3 arm64-build/pack-initrd.py android16-work/control
qemu-system-aarch64 -machine virt,gic-version=2 -cpu cortex-a57 -smp 2 -m 2048 -nodefaults -display none -monitor none -serial file:android16-work/evidence/serial.log -no-reboot \
 -kernel android16-work/kernel/arm64-kernel/Image -initrd android16-work/control/initrd.gz \
 -append "console=ttyAMA0 rdinit=/init panic=-1 nokaslr selinux=0 miao.android=1" \
 -drive file=android16-work/root.ext4,if=none,id=system,format=raw -device virtio-blk-pci,drive=system \
 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:15555-:5555 -device virtio-net-pci,netdev=net0,romfile= >android16-work/evidence/qemu.log 2>&1 &
vm_pid=$!
trap 'kill "$vm_pid" 2>/dev/null || true' EXIT
ready=false
installed=false
running=false
interaction=false
for attempt in $(seq 1 120); do
 adb connect 127.0.0.1:15555 >/dev/null 2>&1 || true
 boot=$(timeout 4 adb -s 127.0.0.1:15555 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
 if [ "$boot" = 1 ]; then ready=true;break;fi
 if ! kill -0 "$vm_pid" 2>/dev/null; then break;fi
 sleep 5
done
if [ "$ready" = true ]; then
 adb -s 127.0.0.1:15555 shell getprop >android16-work/evidence/properties.txt
 curl --fail --location --retry 3 'https://mi-android-online-juaramir1.juanpabloramirez.chatgpt.site/examples/ApiDemos-debug.apk' -o android16-work/ApiDemos.apk
 echo 'b13059630dfea8ec2828797911e4ce1893be3adac5cc9db61421434f7987f2d3  android16-work/ApiDemos.apk' | sha256sum -c -
 if adb -s 127.0.0.1:15555 install --no-streaming android16-work/ApiDemos.apk >android16-work/evidence/install.txt 2>&1; then
   adb -s 127.0.0.1:15555 shell pm path io.appium.android.apis >android16-work/evidence/package-path.txt
   if grep -q '^package:' android16-work/evidence/package-path.txt; then installed=true;fi
 fi
 if [ "$installed" = true ]; then
   adb -s 127.0.0.1:15555 shell monkey -p io.appium.android.apis -c android.intent.category.LAUNCHER 1 >android16-work/evidence/launch.txt 2>&1 || true
   sleep 8
   adb -s 127.0.0.1:15555 shell dumpsys activity activities >android16-work/evidence/activity-before.txt
   if grep -E '(mResumedActivity|topResumedActivity).*io.appium.android.apis' android16-work/evidence/activity-before.txt; then running=true;fi
   adb -s 127.0.0.1:15555 exec-out screencap -p >android16-work/evidence/apidemos-before.png
   adb -s 127.0.0.1:15555 shell input keyevent 20 20 20 66 >android16-work/evidence/input.txt 2>&1 || true
   sleep 5
   adb -s 127.0.0.1:15555 shell dumpsys activity activities >android16-work/evidence/activity-after.txt
   grep -E '(mResumedActivity|topResumedActivity).*io.appium.android.apis' android16-work/evidence/activity-before.txt >android16-work/evidence/focus-before.txt || true
   grep -E '(mResumedActivity|topResumedActivity).*io.appium.android.apis' android16-work/evidence/activity-after.txt >android16-work/evidence/focus-after.txt || true
   if [ "$running" = true ] && [ -s android16-work/evidence/focus-after.txt ] && ! cmp -s android16-work/evidence/focus-before.txt android16-work/evidence/focus-after.txt; then interaction=true;fi
 fi
 python3 android16-build/test-probes.py
 adb -s 127.0.0.1:15555 shell dumpsys activity activities >android16-work/evidence/activity.txt
 adb -s 127.0.0.1:15555 exec-out screencap -p >android16-work/evidence/android16.png
fi
timeout 15 adb -s 127.0.0.1:15555 logcat -d >android16-work/evidence/logcat.txt 2>&1 || true
printf '{"androidBootedNative":%s,"androidBootedBrowser":false,"apkInstalledNative":%s,"apkExecutedNative":%s,"interactionVerifiedNative":%s,"imageDigest":"%s","kernelRunId":"%s"}\n' "$ready" "$installed" "$running" "$interaction" "$digest" "$KERNEL_RUN_ID" >android16-work/evidence/result.json
git rev-parse HEAD >android16-work/evidence/recipe-commit.txt
tail -n 180 android16-work/evidence/serial.log
cat android16-work/evidence/result.json
# Preservar sólo evidencia, recetas y nuestro initrd. No publicar el sistema upstream ni archivos privados.
cp android16-work/control/initrd.gz android16-work/evidence/
cp android16-build/init-android.c android16-work/evidence/
