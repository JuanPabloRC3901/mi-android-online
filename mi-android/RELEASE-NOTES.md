Compilación experimental de QEMU-Wasm x86_64 con SDL y Pixman explícito.

El heap solicitado es de 3584 MiB; incluye las estructuras del emulador y no equivale a la RAM del Android invitado. No se verificaron todavía arranque Android, instalación APK o interacción con aplicaciones en esta compilación. No añade traducción ARM/ARM64 y no reemplaza automáticamente el motor v86 del sitio.

El paquete de fuentes correspondientes incluye QEMU, SDL, los parches y configuración de Linux Lab y Mi Android, y los fuentes utilizados de zlib, libffi, glib y Pixman. Mantener los avisos y licencias de cada componente; el binario QEMU se distribuye con sus condiciones GPL.

La compilación usa un runner público estándar. Los archivos se entregan como assets de una prerelease; no se usa almacenamiento de artefactos de Actions, caches, Packages, LFS ni Codespaces. No se ejecuta un servidor Android ni se instala un compilador en el PC del usuario.

Referencias:
- https://github.com/dbontr/linux-lab/tree/3a2233b01d65743886413c1f3c3dd76eee931e31
- https://github.com/ktock/qemu-wasm/tree/0ef7b4e2814b231705d8371dd7997f5b72e70baf
- https://github.com/libsdl-org/SDL/tree/55b03c7493a7abed33cf803d1380a40fa8af903f
- https://docs.github.com/en/actions/concepts/billing-and-usage
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
