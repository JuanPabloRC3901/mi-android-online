// Diagnóstico en GitHub: interpretar instrucciones con TCI en lugar del JIT Wasm.
// Mantiene hardware y memoria del intento previo; no confirma Android o APK.
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const root=resolve(process.argv[2]||'qemu-source');
const file=resolve(root,'runtime-build/qemu/build.sh');
let source=await readFile(file,'utf8');
const config='  --enable-sdl \\\n',memory='-sTOTAL_MEMORY=2300MB';
if(source.split(config).length!==2||source.split(memory).length!==2||source.includes('--enable-tcg-interpreter'))throw Error('La configuración upstream cambió; detener la compilación.');
if(/-s(?:DEFAULT_PTHREAD_STACK_SIZE|STACK_SIZE|STACK_OVERFLOW_CHECK|ASSERTIONS)=/.test(source))throw Error('Upstream ya define stacks o comprobaciones; revisar.');
source=source.replace(config,config+'  --enable-pixman \\\n  --enable-tcg-interpreter \\\n');
source=source.replace(memory,'-sTOTAL_MEMORY=3584MB -sSTACK_SIZE=4MB -sDEFAULT_PTHREAD_STACK_SIZE=2MB -sASSERTIONS=1 -sSTACK_OVERFLOW_CHECK=2');
await writeFile(file,source);
console.log('QEMU TCI diagnóstico, SDL/Pixman, heap 3584 MiB y stacks ampliados; Android y rendimiento sin verificar.');
