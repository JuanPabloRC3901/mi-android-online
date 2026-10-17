# MIT. Verificación Android real mediante ADB y texto accesible de la app propia.
from pathlib import Path
import json,re,subprocess,time,xml.etree.ElementTree as ET
out=Path("android16-work/evidence")
def adb(*args,timeout=60):
 return subprocess.run(["adb","-s","127.0.0.1:15555",*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
def ui():
 adb("shell","uiautomator","dump","/data/local/tmp/miao-ui.xml")
 r=adb("shell","cat","/data/local/tmp/miao-ui.xml")
 return r.stdout.decode(errors="replace")
results=[]
for mode,abi in [("arm64","arm64-v8a"),("arm32","armeabi-v7a")]:
 result=dict(mode=mode,expectedABI=abi,installed=False,running=False,interactionVerified=False)
 try:
  apk=out/("native-probe-"+mode+".apk")
  r=adb("install","--no-streaming",str(apk))
  (out/(mode+"-install.txt")).write_bytes(r.stdout+r.stderr)
  pkg="cl.miao.nativeprobe."+mode
  result["installed"]=r.returncode==0 and adb("shell","pm","path",pkg).stdout.startswith(b"package:")
  if result["installed"]:
   r=adb("shell","am","start","-W","-n",pkg+"/cl.miao.nativeprobe.MainActivity")
   (out/(mode+"-launch.txt")).write_bytes(r.stdout+r.stderr)
   time.sleep(3)
   before=ui();(out/(mode+"-before.xml")).write_text(before)
   (out/(mode+"-before.png")).write_bytes(adb("exec-out","screencap","-p").stdout)
   result["running"]=("ABI nativa: "+abi) in before and "Contador nativo: 0" in before
   tree=ET.fromstring(before)
   button=next((n for n in tree.iter("node") if n.attrib.get("text")=="Sumar"),None)
   if result["running"] and button is not None:
    v=[int(x) for x in re.findall(r"\d+",button.attrib["bounds"])]
    result["touch"]=[(v[0]+v[2])//2,(v[1]+v[3])//2]
    adb("shell","input","tap",*[str(x) for x in result["touch"]])
    time.sleep(2)
    after=ui();(out/(mode+"-after.xml")).write_text(after)
    (out/(mode+"-after.png")).write_bytes(adb("exec-out","screencap","-p").stdout)
    result["interactionVerified"]=("ABI nativa: "+abi) in after and "Contador nativo: 1" in after
 except Exception as e:
  result["error"]=str(e)
 results.append(result)
(out/"native-probes.json").write_text(json.dumps(results,indent=2))
print(json.dumps(results,indent=2))

# El resultado del proceso exige ambas ABI y una interacción real con JNI.
raise SystemExit(0 if all(r["installed"] and r["running"] and r["interactionVerified"] for r in results) else 1)
