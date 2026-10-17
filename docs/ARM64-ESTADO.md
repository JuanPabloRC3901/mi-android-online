# Estado verificable del motor ARM64

Corte: 17 de octubre de 2026, 20:17 (Chile).

El sitio público continúa con Android 4.4 x86. La variante ARM64 todavía **no demuestra Android 16 funcionando en el navegador ni instalación de APK allí**.

| Comprobación | Resultado real |
|---|---|
| Linux 6.6.159 ARM64 en WebAssembly TCI | Aprobado en el navegador |
| Programa ARM de 32 bits | Ejecutado, salida 0 |
| Binder, hwbinder y vndbinder | Protocolo 8 en los tres |
| Shim oficial Android memfd/ashmem | Tamaño, protección y rechazo de restaurar escritura verificados en ARM64; compat_ioctl ARM32 también verificado |
| VirtIO RNG | Lectura real de 16 bytes en el navegador |
| Tiempo de la prueba de componentes | 26,11 s; incluye carga/arranque, no es tiempo de arranque de Android |
| Cliente JavaScript y puente ARM64 | Transferencia real de 12 MiB+3 bytes, comparación completa del archivo y validación de CRC |
| Medición de transferencia | 3,48 s en QEMU user de GitHub, **no es una medición del navegador ni una instalación de APK** |
| Android 16 completo | Aún sin validar; último ensayo completado falló y hay otro con el núcleo corregido |
| APK JNI ARM64 y ARM32 | Compilación y firmas v2/v3 verificadas; ejecución en Android aún pendiente |

## Evidencias

- [Resultado original del navegador](evidence/browser-memory-shim.json).
- [Resultado del transporte JavaScript/ARM64](evidence/serial-transfer.json). El archivo de prueba contiene datos binarios, no un APK ejecutable.
- [Compilación y prueba del núcleo](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/39077455842).
- [Binarios del núcleo y fuentes GPL correspondientes](https://github.com/JuanPabloRC3901/mi-android-online/releases/tag/mi-android-arm64-39077455842-1-kernel).
- [Prueba del puente y comparación del archivo](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/39078264948).
- [Ensayo Android 16 con ese núcleo](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/39077861745). Consultar result.json: un artefacto publicado no significa que Android haya arrancado.

## Código y reproducción sin instalar herramientas en Windows

Las recetas están en `arm64-build/` y `android16-build/`. Los workflows de `.github/workflows/` compilan en runners públicos estándar efímeros. Los SDK/NDK del runner ya estaban preinstalados. No se instalaron compiladores, Docker, SDK ni emuladores en el PC.

El núcleo base se verifica por SHA256. El componente de memoria proviene de [Android Common, commit e148935a1d484f8a9a0742acbb22ca966f8067df](https://github.com/aosp-mirror/kernel_common/tree/e148935a1d484f8a9a0742acbb22ca966f8067df), con sus avisos GPL conservados e incluidos en las fuentes correspondientes.

El motor rápido JIT presentó caracteres UART duplicados y no se seleccionó como estable. TCI es la variante que pasó las comprobaciones registradas.

Falta completar el arranque Android, verificar los APK y la interacción real con la interfaz, integrar el disco y el puente en el navegador y medir su rendimiento allí. No existe aún una URL pública funcional de esta variante moderna. No hay servidores de emulación alojados en GitHub Actions; sólo compilaciones y pruebas temporales.
