// MIT. Prueba nativa de Android real: no equivale a funcionamiento en navegador.
import {spawn,execFileSync} from 'node:child_process';
import{readFile,writeFile}from'node:fs/promises';
import assert from'node:assert/strict';
import{SerialBridge}from'./serial-client.mjs';
const serial='127.0.0.1:15555',out='android16-work/evidence/';
const adb=(...args)=>execFileSync('adb',['-s',serial,...args],{timeout:60000,maxBuffer:8*1024*1024});
adb('push','android16-work/probe/miao-bridge-arm64','/data/local/tmp/miao-bridge');
adb('shell','chmod','755','/data/local/tmp/miao-bridge');
const child=spawn('adb',['-s',serial,'shell','-T','/data/local/tmp/miao-bridge','--stdio'],{stdio:['pipe','pipe','pipe']});
let stderr='';child.stderr.on('data',b=>stderr+=b.toString());
const bridge=new SerialBridge(b=>child.stdin.write(b));
child.stdout.on('data',b=>bridge.feed(b));child.on('exit',()=>bridge.disconnect());child.on('error',()=>bridge.disconnect());
const result={androidBootedNative:false,bridgeVerifiedNative:false,androidBootedBrowser:false,apps:[]};
const delay=ms=>new Promise(r=>setTimeout(r,ms));
async function ui(expected){
 for(let i=0;i<5;i++){
  adb('shell','uiautomator','dump','/data/local/tmp/miao-bridge-ui.xml');
  const xml=adb('shell','cat','/data/local/tmp/miao-bridge-ui.xml').toString();
  if(expected.every(text=>xml.includes(text)))return xml;
  await delay(2000);
 }
 throw Error('La interfaz real no mostró los textos esperados');
}
try{
 const props=await bridge.info();await writeFile(out+'bridge-properties.json',JSON.stringify(props,null,2));
 assert.equal(props['sys.boot_completed'],'1');assert.equal(props['ro.build.version.sdk'],'36');result.androidBootedNative=true;
 for(const[mode,abi]of[['arm64','arm64-v8a'],['arm32','armeabi-v7a']]){
  const pkg='cl.miao.nativeprobe.'+mode;
  const app={mode,abi,installed:false,executed:false,interactionVerified:false};result.apps.push(app);
  const bytes=await readFile(out+'native-probe-'+mode+'.apk');
  const installed=await bridge.install(new File([bytes],mode+'.apk'),pkg);
  app.installed=installed.installed;app.packagePath=installed.path;
  adb('shell','am','force-stop',pkg);
  await bridge.success('launch',pkg);
  const before=await ui(['ABI nativa: '+abi,'Contador nativo: 0']);app.executed=true;
  await writeFile(out+'bridge-'+mode+'-before.xml',before);
  await writeFile(out+'bridge-'+mode+'-before.png',Buffer.from(await(await bridge.screenshot()).arrayBuffer()));
  const node=before.match(/<node\b[^>]*text="Sumar"[^>]*>/)?.[0],bounds=node?.match(/bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/);
  assert.ok(bounds,'Botón real Sumar no encontrado');const v=bounds.slice(1).map(Number),x=Math.floor((v[0]+v[2])/2),y=Math.floor((v[1]+v[3])/2);
  await bridge.success('tap',x+' '+y);
  const after=await ui(['ABI nativa: '+abi,'Contador nativo: 1']);app.interactionVerified=true;app.touch=[x,y];
  await writeFile(out+'bridge-'+mode+'-after.xml',after);
  await writeFile(out+'bridge-'+mode+'-after.png',Buffer.from(await(await bridge.screenshot()).arrayBuffer()));
 }
 result.bridgeVerifiedNative=result.apps.length===2&&result.apps.every(a=>a.installed&&a.executed&&a.interactionVerified);
}catch(e){result.error=String(e);result.stderr=stderr;}
finally{bridge.disconnect();child.kill('SIGTERM');await writeFile(out+'android-bridge-result.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result,null,2));}
if(!result.bridgeVerifiedNative)process.exitCode=1;
