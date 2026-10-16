// Se ejecuta en GitHub; no instala un compilador en el PC del usuario.
// Hipótesis: evitar corrupción de TLS por stacks pthread de 64 KiB.
// Referencias: ktock/qemu-wasm#50 y settings_reference de Emscripten.
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const root=resolve(process.argv[2]||'qemu-source');
const file=resolve(root,'runtime-build/qemu/build.sh');
let source=await readFile(file,'utf8');
const config='  --enable-sdl \\\n';
const memory='-sTOTAL_MEMORY=2300MB';
if(source.split(config).length!==2||source.split(memory).length!==2)throw Error('La configuración upstream cambió; detener la compilación.');
if(/-s(?:DEFAULT_PTHREAD_STACK_SIZE|STACK_SIZE|STACK_OVERFLOW_CHECK|ASSERTIONS)=/.test(source))throw Error('Upstream ya define stacks o comprobaciones; revisar antes de reemplazar.');
source=source.replace(config,config+'  --enable-pixman \\\n');
source=source.replace(memory,'-sTOTAL_MEMORY=3584MB -sSTACK_SIZE=4MB -sDEFAULT_PTHREAD_STACK_SIZE=2MB -sASSERTIONS=1 -sSTACK_OVERFLOW_CHECK=2');
await writeFile(file,source);
console.log('QEMU diagnóstico: SDL/Pixman, heap fijo 3584 MiB, stack main 4 MiB, pthread 2 MiB y comprobación de desbordamientos. No confirma Android ni APK.');
