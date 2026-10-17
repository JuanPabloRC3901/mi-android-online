# MIT. Sólo inventario del sistema abierto de upstream; no se publica el sistema.
from pathlib import Path
import hashlib,json,os
root=Path("android16-work/rootfs")
paths=["bootstrap-apex","apex","linkerconfig","mnt","init","system/bin/init","system/build.prop","vendor/build.prop","system/etc/init/hw/init.rc","vendor/etc/init/hw/init.redroid.rc"]
out={"rootEntries":sorted(p.name for p in root.iterdir())}
for name in paths:
 p=root/name
 if p.is_symlink():out[name]={"symlink":os.readlink(p)}
 elif p.is_dir():out[name]={"directory":True}
 elif p.is_file():
  b=p.read_bytes()
  out[name]={"bytes":len(b),"sha256":hashlib.sha256(b).hexdigest()}
  if name.endswith((".rc",".prop")):out[name]["text"]=b.decode(errors="replace")[:50000]
out["nativeLibraries"]={d: sorted(x.name for x in (root/d).glob("*"))[:25] for d in ["system/lib","system/lib64","vendor/lib","vendor/lib64"]}
Path("android16-work/evidence/image-inspection.json").write_text(json.dumps(out,indent=2))
print(json.dumps({"rootEntries":out["rootEntries"],"inspectedPaths":list(out),"fullInventory":"evidence/image-inspection.json"},indent=2))
