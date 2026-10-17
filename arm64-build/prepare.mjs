// Variante propia ARM64 de QEMU-Wasm. No modifica el sitio publicado.
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const root=resolve(process.argv[2]||'qemu-source');
const mode=process.argv[3]||'tci';
if(!['jit','tci'].includes(mode))throw Error('Modo desconocido');
const file=resolve(root,'runtime-build/qemu/build.sh');
let s=await readFile(file,'utf8');
function once(before,after){if(s.split(before).length!==2)throw Error('Upstream inesperado: '+before.slice(0,70));s=s.replace(before,after);}
once('--target-list=x86_64-softmmu','--target-list=aarch64-softmmu');
once('  --enable-sdl \\\n','  --enable-sdl \\\n  --enable-pixman \\\n  --enable-fdt \\\n'+(mode==='tci'?'  --enable-tcg-interpreter \\\n':''));
once('-sTOTAL_MEMORY=2300MB','-sTOTAL_MEMORY=2048MB -sSTACK_SIZE=4MB -sDEFAULT_PTHREAD_STACK_SIZE=2MB -sASSERTIONS=1 -sSTACK_OVERFLOW_CHECK=2');
const start=s.indexOf('for firmware in \\\n'),end=s.indexOf('docker cp "$PACK_DIR" "$CONTAINER_NAME:/pack"');
if(start<0||end<start)throw Error('Bloque de firmware inesperado');
s=s.slice(0,start)+'printf "%s\\n" "ARM64 virt: arranque directo de Image e initrd, sin firmware PC." > "$PACK_DIR/README.txt"\n\n'+s.slice(end);
s=s.replaceAll('qemu-system-x86_64','qemu-system-aarch64').replaceAll('"architecture": "x86_64"','"architecture": "aarch64"').replaceAll('QEMU-Wasm x86_64','QEMU-Wasm ARM64');
if(s.includes('qemu-system-x86_64')||!s.includes('--enable-fdt'))throw Error('Conversión incompleta');
await writeFile(file,s);
console.log('ARM64 '+mode+': heap diagnóstico 2048 MiB, stacks 4/2 MiB. Android y APK sin verificar.');
