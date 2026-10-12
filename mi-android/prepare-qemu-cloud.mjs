// Se ejecuta sólo en el runner Linux de GitHub, nunca en el PC del usuario.
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const root = resolve(process.argv[2] || 'qemu-source');
const file = resolve(root, 'runtime-build/qemu/build.sh');
let source = await readFile(file, 'utf8');
const config = '  --enable-sdl \\\n';
if (!source.includes(config) || !source.includes('-sTOTAL_MEMORY=2300MB')) throw Error('La configuración upstream cambió; detener la compilación.');
source = source.replace(config, config + '  --enable-pixman \\\n');
source = source.replace('-sTOTAL_MEMORY=2300MB', '-sTOTAL_MEMORY=3584MB');
await writeFile(file, source);
console.log('Configuración preparada: SDL + Pixman; heap WebAssembly de 3584 MiB. Esto aún no confirma RAM de Android ni compatibilidad APK.');
