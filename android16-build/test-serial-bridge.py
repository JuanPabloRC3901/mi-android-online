# MIT. Protocolo real con binario ARM64 bajo QEMU user en GitHub.
import base64,binascii,json,os,pty,select,subprocess,sys,time
from pathlib import Path
binary=Path(sys.argv[1]);directory=Path(sys.argv[2]);directory.mkdir(mode=0o700)
master,slave=pty.openpty()
process=subprocess.Popen(["qemu-aarch64",str(binary),os.ttyname(slave)],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
os.close(slave)
pending=b"";sequence=0
def call(verb,arg=""):
 global sequence,pending
 sequence+=1;ident=str(sequence)
 os.write(master,("MIAO1 "+ident+" "+verb+" "+arg+"\n").encode())
 data=bytearray();meta=None;deadline=time.monotonic()+15
 while time.monotonic()<deadline:
  if b"\n" not in pending:
   if not select.select([master],[],[],max(0,deadline-time.monotonic()))[0]:break
   pending+=os.read(master,65536)
  if b"\n" not in pending:continue
  line,pending=pending.split(b"\n",1)
  tokens=line.strip().split()
  if len(tokens)<3 or tokens[:2]!=[b"MIAO1",ident.encode()]:continue
  if tokens[2]==b"begin":
   if len(tokens)!=7:raise AssertionError("cabecera")
   meta={"kind":tokens[3].decode(),"code":int(tokens[4]),"size":int(tokens[5]),"crc":int(tokens[6],16)}
  elif tokens[2]==b"chunk":
   if len(tokens)!=5 or int(tokens[3])!=len(data):raise AssertionError("orden de salida")
   data.extend(base64.b64decode(tokens[4],validate=True))
  elif tokens[2]==b"end":
   assert meta and len(data)==meta["size"] and binascii.crc32(data)==meta["crc"]
   return meta,bytes(data)
 raise TimeoutError(verb)
checks=[]
def check(name,condition):
 assert condition,name
 checks.append(name)
try:
 m,b=call("ping");check("ping real",m["code"]==0 and b"puente" in b)
 check("sin instalación previa",call("install")[0]["code"]!=0)
 check("rechazo de shell en paquete",call("launch","x.y;id")[0]["code"]!=0)
 check("rechazo de coordenadas",call("tap","99999 0")[0]["code"]!=0)
 check("rechazo de comando desconocido",call("inventado")[0]["code"]!=0)
 sample=b"PK\x03\x04"+bytes(range(256))*32
 check("inicio APK real",call("apk-begin",str(len(sample)))[0]["code"]==0)
 check("rechazo de offset incorrecto",call("apk-chunk","1 "+base64.b64encode(b"x").decode())[0]["code"]!=0)
 for offset in range(0,len(sample),6144):
  chunk=sample[offset:offset+6144]
  m,b=call("apk-chunk",str(offset)+" "+base64.b64encode(chunk).decode())
  check("fragmento "+str(offset),m["code"]==0 and b.decode()==str(offset+len(chunk)))
 check("rechazo de suma incorrecta",call("apk-finish","00000000")[0]["code"]!=0)
 check("rechazo de instalación sin confirmar",call("install")[0]["code"]!=0)
 check("fin con CRC real",call("apk-finish",f"{binascii.crc32(sample):08x}")[0]["code"]==0)
 check("bytes íntegros en disco",(directory/"miao-upload.apk").read_bytes()==sample)
 check("no simula Android",call("install")[0]["code"]==127)
 check("rechazo de tamaño mayor a 1GiB",call("apk-begin","1073741825")[0]["code"]!=0)
 check("nuevo intento invalida instalación anterior",call("install")[0]["code"]!=0)
 print(json.dumps({"protocolVerified":True,"transferredBytes":len(sample),"checks":checks,"androidBooted":False,"apkInstalled":False},ensure_ascii=False,indent=2))
finally:
 process.terminate()
 try:process.wait(timeout=3)
 except subprocess.TimeoutExpired:process.kill();process.wait()
 os.close(master)
