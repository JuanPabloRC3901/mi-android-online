#!/usr/bin/env python3
"""Diagnóstico acotado de esta imagen efímera; no procesa APK ni archivos del usuario."""
from pathlib import Path
import gzip
root = Path("android16-work/evidence")
for path in sorted((root / "tombstones").rglob("tombstone_*")):
    if path.suffix == ".pb" or not path.is_file():
        continue
    print("MIAO_DIAGNOSTIC|TOMBSTONE|" + path.name)
    print(path.read_bytes()[:32768].decode("utf-8", "replace").split("backtrace:", 1)[0][:12000])
for folder in ("dropbox", "boot-logs"):
    for path in sorted((root / folder).rglob("*")):
        if not path.is_file() or path.stat().st_size > 8 * 1024 * 1024:
            continue
        try:
            if path.suffix == ".gz":
                with gzip.open(path, "rb") as stream:
                    data = stream.read(2 * 1024 * 1024)
            else:
                data = path.read_bytes()[:2 * 1024 * 1024]
            text = data.decode("utf-8", "replace")
        except (OSError, EOFError) as error:
            print("MIAO_DIAGNOSTIC|READ_ERROR|" + str(error))
            continue
        lines = text.splitlines()
        hits = [i for i, line in enumerate(lines) if any(term in line for term in (
            "FATAL EXCEPTION", "Fatal signal", "Abort message", "RuntimeException",
            "Caused by:", "SystemServer", "system_server", "Zygote", "avc: denied",
            "Not allowlisted", "Failed to", "failed to", "FatalError"))]
        if hits:
            print("MIAO_DIAGNOSTIC|LOG|" + str(path.relative_to(root)))
            selected = set()
            for i in hits[:35]:
                selected.update(range(max(0, i - 1), min(len(lines), i + 9)))
            for i in sorted(selected)[:220]:
                print(lines[i][:1200])
