// MIT. El cliente JavaScript habla con nuestro binario ARM64 real en QEMU user.
import {spawn} from 'node:child_process';
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {SerialBridge} from './serial-client.mjs';
const child=spawn('qemu-aarch64',['./miao-bridge-test','--stdio'],{stdio:['pipe','pipe','pipe']});
let stderr='';child.stderr.on('data',b=>stderr+=b.toString());
const bridge=new SerialBridge(bytes=>child.stdin.write(bytes),{timeoutMs:30000});
child.stdout.on('data',b=>{bridge.feed(b.subarray(0,7));bridge.feed(b.subarray(7));});
child.on('error',()=>bridge.disconnect());child.on('exit',()=>bridge.disconnect());
const checks=[];
try{
 const ping=await bridge.success('ping');assert.match(ping.text(),/puente/);checks.push('ping ARM64 desde JavaScript');
 await assert.rejects(bridge.info(),/código 127/);checks.push('no inventa propiedades Android');
 await assert.rejects(bridge.screenshot(),/código 127/);checks.push('no inventa una pantalla');
 const bytes=Uint8Array.from({length:17011},(_,i)=>(i*37)&255),file=new File([bytes],'fixture-binary.bin');
 let confirmed=0;const result=await bridge.upload(file,{onProgress:(done,total)=>{assert.equal(total,file.size);assert.ok(done>confirmed);confirmed=done;}});
 assert.equal(result.installed,false);assert.equal(confirmed,file.size);assert.deepEqual(new Uint8Array(await readFile('/tmp/miao-bridge-ci/miao-upload.apk')),bytes);checks.push('17011 bytes transferidos por tres fragmentos y verificados en disco');
 await assert.rejects(bridge.install(file,'cl.miao.fixture'),/código 127/);checks.push('no declara instalación sin PackageManager');
 await assert.rejects(bridge.request('tap','1 2\nMIAO1 4 install'),/Solicitud inválida/);checks.push('rechaza inyección de otra solicitud');
 console.log(JSON.stringify({javaScriptToArm64Verified:true,checks,androidBooted:false,apkInstalled:false},null,2));
}catch(e){console.error(stderr);throw e;}
finally{bridge.disconnect();child.kill('SIGTERM');}

