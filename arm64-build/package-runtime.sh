#!/usr/bin/env bash
set -euo pipefail
WORK_DIR="/tmp/linux-lab-qemu-wasm"
SOURCE_DIR="$WORK_DIR/source"
SDL_DIR="$WORK_DIR/sdl2"
OUT="$GITHUB_WORKSPACE/qemu-artifact"
CORRESPONDING="$GITHUB_WORKSPACE/qemu-corresponding-source"
test -f "$OUT/qemu-system-aarch64.wasm"
test "$(git -C "$SOURCE_DIR" rev-parse HEAD)" = "0ef7b4e2814b231705d8371dd7997f5b72e70baf"
test -f "$SDL_DIR/src/video/emscripten/SDL_emscriptenframebuffer.c"
mkdir -p "$CORRESPONDING/qemu" "$CORRESPONDING/sdl" "$CORRESPONDING/linux-lab-runtime" "$CORRESPONDING/mi-android"
tar -C "$SOURCE_DIR" --exclude=.git -cf - . | tar -C "$CORRESPONDING/qemu" -xf -
tar -C "$SDL_DIR" --exclude=.git -cf - . | tar -C "$CORRESPONDING/sdl" -xf -
tar -C qemu-source/runtime-build/qemu --exclude=node_modules -cf - . | tar -C "$CORRESPONDING/linux-lab-runtime" -xf -
cp -r mi-android/. "$CORRESPONDING/mi-android/"
cp -r arm64-build "$CORRESPONDING/arm64-recipe"
# Recover actual dependency sources from the same Docker build stages.
# Existing layers are reused on the ephemeral runner, without registry uploads.
extract_source() {
  local stage="$1" directory="$2" name="$3"
  local image="miao-source-${name}:${GITHUB_RUN_ID}"
  local container="miao-source-${name}-${GITHUB_RUN_ID}"
  docker build --target "$stage" -t "$image" -f "$SOURCE_DIR/Dockerfile" "$SOURCE_DIR"
  docker create --name "$container" "$image" true >/dev/null
  docker cp "$container:$directory" "$CORRESPONDING/$name"
  docker rm "$container" >/dev/null
}
extract_source zlib-emscripten-dev /zlib zlib
extract_source libffi-emscripten-dev /libffi libffi
extract_source build-dev /glib glib
extract_source pixman-emscripten-dev /pixman pixman
cp qemu-source/LICENSE "$CORRESPONDING/LICENSE-linux-lab"
cp arm64-build/README.md "$OUT/VALIDACION-PENDIENTE.md"
cp qemu-source/runtime-build/qemu/build.sh "$OUT/build-config.sh"
printf '%s\n' 'experimental=true' 'android_boot_verified=false' 'apk_install_verified=false' 'apk_execution_verified=false' > "$OUT/VALIDACION-PENDIENTE.txt"
tar -czf qemu-corresponding-source.tar.gz -C "$GITHUB_WORKSPACE" qemu-corresponding-source
tar -czf qemu-experimental.tar.gz -C "$GITHUB_WORKSPACE" qemu-artifact
sha256sum qemu-experimental.tar.gz qemu-corresponding-source.tar.gz > SHA256SUMS-experimental
test "$(stat -c %s qemu-experimental.tar.gz)" -lt 2147483648
test "$(stat -c %s qemu-corresponding-source.tar.gz)" -lt 2147483648
cat SHA256SUMS-experimental
