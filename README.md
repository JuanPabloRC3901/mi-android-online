# Mi Android Online

El 12 de octubre de 2026 se inició la primera compilación de QEMU-WebAssembly en GitHub. La fase de compilación terminó correctamente y el empaquetado está en curso. Todavía no se verificaron Android ni APK con ese motor.

- [Entrar al emulador publicado](https://mi-android-online-juaramir1.juanpabloramirez.chatgpt.site/)
- [Código fuente completo de la versión 8](https://github.com/JuanPabloRC3901/mi-android-online/releases/tag/source-v8)
- [Registro de la compilación experimental](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/38269961724)

El archivo `mi-android-online-codigo.zip` de la release contiene el proyecto del emulador completo. Los archivos mostrados en la raíz del repositorio son la configuración de la nueva compilación.

El workflow se coloca en `.github/workflows/qemu-experimental.yml`; los scripts y notas se colocan en `mi-android/`. Todo se compila en el runner público estándar de GitHub. No se instala nada en el computador empresarial.

Repositorio público de Mi Android Online en la cuenta JuanPabloRC3901. Aquí se prepara y compila el motor experimental; el Android probado sigue publicado en el sitio enlazado abajo. No se incluyen archivos particulares ni APK privados.

La ejecución es manual desde Actions. Verifica que el repositorio sea público; el workflow se detiene si es privado o pertenece a otro propietario. Obtiene Linux Lab desde un commit fijo, habilita Pixman y solicita un heap de 3584 MiB. No equivale a esa cantidad de RAM Android ni aporta traducción ARM/ARM64.

El resultado esperado se publica como prerelease, junto con los fuentes correspondientes y checksums. No usa almacenamiento de artifacts, caches, Packages, LFS ni Codespaces. El runner estándar público es gratuito; los assets de Releases son la vía de entrega. No se habilitan servicios de pago ni se ejecuta Android en el servidor. Referencias: https://docs.github.com/en/actions/concepts/billing-and-usage y https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases.

Antes de sustituir v86 se deben comprobar pantalla real, mouse/teclado, arranque completo de Android, instalación de un APK original con checksum idéntico, apertura e interacción. La versión funcional actual sigue disponible en https://mi-android-online-juaramir1.juanpabloramirez.chatgpt.site/ .

Comprobaciones locales: el preparador de flags se ejecutó sobre la configuración upstream; el parche upstream de zlib y allocator se ejecutó sobre su Dockerfile; la descarga fijada de zlib coincidió con SHA256 d9e270d46252734aa49770fbc544125391617956266f220bd63216c834f3a522. No hubo analizador YAML disponible y no se instaló uno. GitHub validó y ejecutó el workflow. La recuperación y empaquetado de fuentes dentro del runner siguen en curso.
