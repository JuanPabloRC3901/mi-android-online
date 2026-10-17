// MIT. Crea un archivo de prueba, sin código Android ni APK.
import {writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const bytes=Buffer.alloc(2*1024*1024);
bytes.write('MIAO_DISK_TEST_ONLY');bytes[450]=0x83;bytes.writeUInt32LE(2048,454);bytes.writeUInt32LE(1024,458);bytes[510]=0x55;bytes[511]=0xaa;
await writeFile('miao-mbr-test.img',bytes,{flag:'wx'});
console.log(createHash('sha256').update(bytes).digest('hex'));
