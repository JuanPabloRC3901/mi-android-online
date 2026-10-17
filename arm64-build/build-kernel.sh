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
make O=build defconfig
# Esta máquina es virt; no necesita controladores de placas físicas ARM.
for platform in $(sed -n 's/^config \(ARCH_[A-Z0-9_]*\)$/\1/p; s/^menuconfig \(ARCH_[A-Z0-9_]*\)$/\1/p' arch/arm64/Kconfig.platforms); do
  scripts/config --file build/.config --disable "$platform"
done
scripts/config --file build/.config --enable ARCH_VEXPRESS --disable KVM
scripts/kconfig/merge_config.sh -m -O build build/.config "$ROOT/arm64-build/kernel.config"
make O=build olddefconfig
for flag in COMPAT BINFMT_ELF ANDROID_BINDER_IPC ANDROID_BINDERFS MEMFD_CREATE DEVTMPFS VIRTIO_BLK EXT4_FS SERIAL_AMBA_PL011_CONSOLE ARM_GIC ARM_PSCI_FW; do
  grep -qx "CONFIG_$flag=y" build/.config || { echo "Falta CONFIG_$flag"; exit 1; }
done
make O=build -j"$(nproc)" Image
cp build/arch/arm64/boot/Image "$OUT/Image"
cp build/.config "$OUT/kernel.config"
cp COPYING "$OUT/COPYING.kernel"
cp "$ROOT/arm64-build/init.c" "$OUT/init.c"
cp "$ROOT/arm64-build/compat.S" "$OUT/compat.S"
aarch64-linux-gnu-gcc -Os -ffreestanding -fno-builtin -fno-stack-protector -nostdlib -static -Wl,--build-id=none -Wl,-e,_start "$OUT/init.c" -o "$OUT/init64"
arm-linux-gnueabihf-gcc -nostdlib -static -Wl,--build-id=none -Wl,-e,_start "$OUT/compat.S" -o "$OUT/arm32-probe"
python3 "$ROOT/arm64-build/pack-initrd.py" "$OUT"
printf '%s\n' 'Android no arrancado: esto es un núcleo y una prueba de arquitectura/Binder.' > "$OUT/VALIDACION.txt"
set +e
timeout 90 qemu-system-aarch64 -machine virt,gic-version=2 -cpu cortex-a57 -smp 1 -m 768 -nodefaults -display none -serial stdio -monitor none -nic none -no-reboot -kernel "$OUT/Image" -initrd "$OUT/initrd.gz" -append "console=ttyAMA0 rdinit=/init panic=-1 nokaslr miao.autopoweroff=1" > "$OUT/native-control.log" 2>&1
status=$?
set -e
cat "$OUT/native-control.log"
test "$status" = 0
grep -q 'MIAO_ARM|INIT64_STARTED' "$OUT/native-control.log"
grep -q 'MIAO_ARM|MACHINE|aarch64' "$OUT/native-control.log"
grep -q 'MIAO_ARM|ARM32_EXECUTED' "$OUT/native-control.log"
grep -q 'MIAO_ARM|ARM32_STATUS|0' "$OUT/native-control.log"
grep -q 'MIAO_ARM|BINDER_PROTOCOL|8' "$OUT/native-control.log"
grep -q 'MIAO_ARM|CONTROL_COMPLETE|ANDROID_NOT_BOOTED' "$OUT/native-control.log"
cd "$OUT"
sha256sum Image kernel.config init64 arm32-probe initrd.gz native-control.log init.c compat.S COPYING.kernel VALIDACION.txt > SHA256SUMS
cd "$ROOT"
tar -czf arm64-kernel.tar.gz arm64-kernel
mkdir -p arm64-kernel-corresponding-source
cp "linux-$VERSION.tar.xz" arm64-kernel-corresponding-source/
cp -r arm64-build arm64-kernel-corresponding-source/recipe
cp "$OUT/kernel.config" arm64-kernel-corresponding-source/
tar -czf arm64-kernel-source.tar.gz arm64-kernel-corresponding-source
sha256sum arm64-kernel.tar.gz arm64-kernel-source.tar.gz > SHA256SUMS-arm64-kernel
