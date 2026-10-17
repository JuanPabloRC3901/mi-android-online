# MIT: archivo cpio newc mínimo, sin depender de herramientas instaladas en el PC.
from pathlib import Path
import gzip, struct, sys
root=Path(sys.argv[1])
data=bytearray()
def entry(name, mode, payload=b"", ino=1):
    name=name.encode()+b"\0"
    header=b"070701"+b"".join(f"{x:08x}".encode() for x in (ino,mode,0,0,1,0,len(payload),0,0,0,0,len(name),0))
    data.extend(header+name)
    data.extend(b"\0"*((-len(data))%4))
    data.extend(payload)
    data.extend(b"\0"*((-len(data))%4))
entry(".",0o40755)
for p in ("bin","dev","proc","sys"): entry(p,0o40755)
entry("init",0o100755,(root/"init64").read_bytes())
entry("bin/arm32-probe",0o100755,(root/"arm32-probe").read_bytes())
entry("TRAILER!!!",0)
(root/"initrd.gz").write_bytes(gzip.compress(bytes(data),mtime=0))
