# Receta propia MIT; componentes vendorizados mantienen GPL-2.0.
from pathlib import Path
import shutil,sys
root=Path(sys.argv[1]).resolve()
vendor=Path(__file__).resolve().parent/"android-common"
shmem=root/"mm/shmem.c"
s=shmem.read_text()
if "memfd_ashmem_shim_ioctl" in s:raise SystemExit("Shim ya presente")
anchor='#include "internal.h"'
if s.count(anchor)!=1:raise SystemExit("include upstream inesperado")
s=s.replace(anchor,anchor+'\n\n#ifdef CONFIG_MEMFD_ASHMEM_SHIM\n#include "memfd-ashmem-shim.h"\n#endif')
anchor="const struct file_operations shmem_file_operations = {"
if s.count(anchor)!=1:raise SystemExit("file_operations upstream inesperado")
s=s.replace(anchor,anchor+'\n#ifdef CONFIG_MEMFD_ASHMEM_SHIM\n\t.unlocked_ioctl = memfd_ashmem_shim_ioctl,\n#ifdef CONFIG_COMPAT\n\t.compat_ioctl = memfd_ashmem_shim_compat_ioctl,\n#endif\n#endif')
shmem.write_text(s)
for name in ["memfd-ashmem-shim.c","memfd-ashmem-shim.h","memfd-ashmem-shim-internal.h"]:
 shutil.copyfile(vendor/"mm"/name,root/"mm"/name)
k=root/"mm/Kconfig"
text=k.read_text()
if "config MEMFD_ASHMEM_SHIM" in text:raise SystemExit("Kconfig ya contiene shim")
k.write_text(text+"""
config MEMFD_ASHMEM_SHIM
	bool "Memfd ashmem ioctl compatibility support"
	depends on MEMFD_CREATE
	help
	  This provides compatibility support for ashmem ioctl commands against
	  memfd file descriptors. This is useful for compatibility on Android
	  for older applications that may use ashmem's ioctl commands on the
	  now memfds passed to them.

	  Unless you are running Android, say N.
""")
m=root/"mm/Makefile"
m.write_text(m.read_text()+"\nobj-$(CONFIG_MEMFD_ASHMEM_SHIM) += memfd-ashmem-shim.o\n")
print("Shim oficial Android Common incorporado; las pruebas deben validar tamaño y sellos.")
