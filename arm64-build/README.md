# Mi Android Online: variante ARM64 propia (experimental)

Se compila desde fuentes abiertas de QEMU-Wasm y Linux. No se está escribiendo un emulador completo desde cero: aprovechamos QEMU como base y mantenemos nuestros cambios y núcleo reproducibles.

Objetivo: Android reciente con CPU ARM64 y procesos ARM de 32 bits. Esto no garantiza compatibilidad con todos los APK, GPU, DRM, servicios de Google o aplicaciones protegidas.

El workflow compila dos motores (JIT Wasm y TCI) y Linux 6.6.159 con Binder/Binderfs, compatibilidad de procesos ARM de 32 bits, VirtIO, módulos y kexec. El núcleo parte de tinyconfig con los controladores virtuales y servicios necesarios. Binder se crea por ioctl sobre Binderfs. El núcleo se verifica primero con QEMU nativo en un runner público efímero. Esa prueba de compilación no aloja Android para usuarios.

Los binarios y fuentes correspondientes se publican como prereleases, con SHA256. No se instala Docker, SDK ni compiladores en el PC del usuario. Las compilaciones ocurren en GitHub Actions estándar del repositorio público, sin runners grandes, caches, Packages, LFS ni Codespaces.

La prueba init64/arm32-probe es una utilidad de diagnóstico propia, NO Android. Android arrancado, instalación de APK y ejecución de APK deben verificarse después en el navegador. Hasta ese momento no se sustituye el motor público v86.

Heap inicial del experimento: 2048 MiB, que incluye motor, memoria del invitado y recursos. No equivale a 2 GB de RAM Android disponibles. Se usa para comprobar la ruta antes de ampliar recursos.

Fuentes fijadas:
- QEMU-Wasm 0ef7b4e2814b231705d8371dd7997f5b72e70baf (GPL)
- Linux Lab 3a2233b01d65743886413c1f3c3dd76eee931e31 (MIT)
- Linux 6.6.159, SHA256 7206727244da5d85f4a03758d29e1c0673f2f01877793f494c0f3638c46b8fa5 (GPLv2)
- Nuestro init.c, compat.S y pack-initrd.py: MIT.

Consultar native-result.json: publicar el artefacto no confirma que las comprobaciones hayan pasado.
