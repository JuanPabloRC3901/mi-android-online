# Mi Android Online

[Entrar al emulador publicado](https://mi-android-online-juaramir1.juanpabloramirez.chatgpt.site/) · [Código completo de la versión 9](https://github.com/JuanPabloRC3901/mi-android-online/releases/tag/source-v9)

El Android probado de la página sigue usando v86, Android 4.4.4/API 19 y x86 de 32 bits. Se verificaron por HTTPS el arranque, la instalación original de ApiDemos y Selendroid, su apertura e interacción. Acepta selección de APK de hasta 256 MiB; no se instaló un APK real de ese tamaño. La RAM predeterminada es 1536 MiB; 2047 MiB es experimental. No ofrece traducción ARM/ARM64 ni compatibilidad con cualquier APK.

## Motor QEMU propio compilado y probado

La compilación completa terminó correctamente el 12 de octubre de 2026: [registro de Actions](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/38269961724). [Binario, fuentes correspondientes y checksums](https://github.com/JuanPabloRC3901/mi-android-online/releases/tag/mi-android-qemu-38269961724-1).

Se habilitaron SDL y Pixman y el módulo tiene un heap compartido fijo de 3584 MiB. Ese heap incluye el motor y sus estructuras; no equivale a 3,5 GB de RAM Android. Los 14 checksums internos del runtime descargado coincidieron. QMP informó 768 MiB de hardware invitado y Linux 3.10.52 produjo registros reales. La captura QMP entregó 800 × 600 píxeles negros. Los perfiles de temporizadores, reloj por instrucciones, calibración y disco completo en memoria no completaron Android READY. No se enviaron órdenes de instalación ni apertura. La prueba icount duró más de 21 minutos y la MEMFS más de cuatro; una prueba SDL bloqueó su pestaña y el usuario la cerró. No se determinó una causa única.

[Resultados y registros](https://mi-android-online-juaramir1.juanpabloramirez.chatgpt.site/engine-research.html). Este motor no sustituyó v86 y tampoco incorpora traducción ARM/ARM64. No se presenta como una versión Android funcional.

## Código y reproducción sin instalaciones en el PC empresarial

El archivo **mi-android-online-codigo.zip** de la release source-v9 contiene el proyecto completo. Los archivos mostrados en la raíz del repositorio contienen la configuración de compilación; el ZIP automático del tag también contiene sólo esa configuración.

El workflow manual .github/workflows/qemu-experimental.yml usa mi-android/ y un runner público estándar Ubuntu 24.04. Obtiene Linux Lab 3a2233b01d65743886413c1f3c3dd76eee931e31, QEMU-Wasm 0ef7b4e2814b231705d8371dd7997f5b72e70baf y SDL 55b03c7493a7abed33cf803d1380a40fa8af903f. Conserva sus parches, incluye los fuentes correspondientes y publica una prerelease. No usa artifacts, cache, Packages, LFS ni Codespaces. [Condiciones de GitHub Actions](https://docs.github.com/en/actions/concepts/billing-and-usage). Android se intentó ejecutar dentro del navegador; el runner sólo compiló. No se instaló un compilador ni Docker en el computador empresarial, ni se habilitaron servicios de pago. No hay APK privados ni archivos particulares en este repositorio.

Para sustituir v86 faltan Android listo, pantalla y entrada funcionales, instalación original con checksum coincidente, apertura e interacción y verificación de RAM dentro del propio Android.
