#!/usr/bin/env bash
set -euo pipefail
ROOT="$GITHUB_WORKSPACE"
VERSION=6.6.159
SHA=7206727244da5d85f4a03758d29e1c0673f2f01877793f494c0f3638c46b8fa5
OUT="$ROOT/arm64-kernel"
mkdir -p "$OUT" "$ROOT/arm64-kernel-source"
curl --fail --location --retry 3 "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$VERSION.tar.xz" -o "$ROOT/linux-$VERSION.tar.xz"
echo "$SHA  $ROOT/linux-$VERSION.tar.xz" | sha256sum -c -
tar -xJf "$ROOT/linux-$VERSION.tar.xz" -C "$ROOT/arm64-kernel-source" --strip-components=1
cd "$ROOT/arm64-kernel-source"
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
python3 "$ROOT/arm64-build/apply-android-memory.py" "$ROOT/arm64-kernel-source"
make O=build tinyconfig
scripts/kconfig/merge_config.sh -m -O build build/.config "$ROOT/arm64-build/kernel.config"
make O=build olddefconfig
for flag in VIRTIO_CONSOLE MEMFD_ASHMEM_SHIM HW_RANDOM HW_RANDOM_VIRTIO COMPAT BINFMT_ELF ANDROID_BINDER_IPC ANDROID_BINDERFS MEMFD_CREATE DEVTMPFS VIRTIO_BLK EXT4_FS SERIAL_AMBA_PL011_CONSOLE ARM_GIC ARM_PSCI_FW; do
  grep -qx "CONFIG_$flag=y" build/.config || { echo "Falta CONFIG_$flag"; exit 1; }
done
cp build/.config "$OUT/kernel.config"
cp COPYING "$OUT/COPYING.kernel"
cp "$ROOT/arm64-build/init.c" "$OUT/init.c"
cp "$ROOT/arm64-build/compat.S" "$OUT/compat.S"
aarch64-linux-gnu-gcc -Os -ffreestanding -fno-builtin -fno-stack-protector -nostdlib -static -Wl,--build-id=none -Wl,-e,_start "$OUT/init.c" -o "$OUT/init64"
arm-linux-gnueabihf-gcc -nostdlib -static -Wl,--build-id=none -Wl,-e,_start "$OUT/compat.S" -o "$OUT/arm32-probe"
python3 "$ROOT/arm64-build/pack-initrd.py" "$OUT"
make O=build -j"$(nproc)" Image
cp build/arch/arm64/boot/Image "$OUT/Image"
printf '%s\n' 'Android no arrancado: esto es un núcleo y una prueba de arquitectura/Binder.' > "$OUT/VALIDACION.txt"
set +e
timeout 90 qemu-system-aarch64 -machine virt,gic-version=2 -cpu cortex-a57 -smp 1 -m 768 -nodefaults -display none -serial none -chardev stdio,id=miao-console -device virtio-serial-pci -device virtconsole,chardev=miao-console -monitor none -nic none -device virtio-rng-pci -no-reboot -kernel "$OUT/Image" -initrd "$OUT/initrd.gz" -append "console=hvc0 rdinit=/init panic=-1 nokaslr miao.autopoweroff=1" > "$OUT/native-control.log" 2>&1
status=$?
set -e
cat "$OUT/native-control.log"
verified=true
if [ "$status" != 0 ]; then verified=false;fi
for marker in 'MIAO_ARM|CONSOLE|hvc0' 'MIAO_ARM|INIT64_STARTED' 'MIAO_ARM|MACHINE|aarch64' 'MIAO_ARM|ARM32_EXECUTED' 'MIAO_ARM|ARM32_STATUS|0' 'MIAO_ARM|BINDER_PROTOCOL|8' 'MIAO_ARM|ASHMEM_COMPAT_SIZE|4096' 'MIAO_ARM|ASHMEM_COMPAT_PROTECT|0' 'MIAO_ARM|ASHMEM_COMPAT_PROT_MASK|5' 'MIAO_ARM|ASHMEM_COMPAT_RESTORE_WRITE|-22' 'MIAO_ARM|ARM32_ASHMEM_COMPAT_VERIFIED' 'MIAO_ARM|HWRNG_BYTES|16' 'MIAO_ARM|CONTROL_COMPLETE|ANDROID_NOT_BOOTED'; do
 if ! grep -q "$marker" "$OUT/native-control.log"; then verified=false;fi
done
printf '{"nativeControlVerified":%s,"qemuExit":%s,"androidBooted":false,"apkInstalled":false}\n' "$verified" "$status" > "$OUT/native-result.json"
cd "$OUT"
sha256sum Image kernel.config init64 arm32-probe initrd.gz native-control.log init.c compat.S COPYING.kernel VALIDACION.txt native-result.json > SHA256SUMS
cd "$ROOT"
tar -czf arm64-kernel.tar.gz arm64-kernel
mkdir -p arm64-kernel-corresponding-source
cp "linux-$VERSION.tar.xz" arm64-kernel-corresponding-source/
cp -r arm64-build arm64-kernel-corresponding-source/recipe
cp "$OUT/kernel.config" arm64-kernel-corresponding-source/
tar -czf arm64-kernel-source.tar.gz arm64-kernel-corresponding-source
sha256sum arm64-kernel.tar.gz arm64-kernel-source.tar.gz > SHA256SUMS-arm64-kernel
test "$verified" = true
