# Estado verificable del motor ARM64

Corte: 17 de octubre de 2026, 20:30 (Chile).

El sitio público continúa con Android 4.4 x86. La variante ARM64 todavía **no demuestra Android 16 funcionando en el navegador ni instalación de APK allí**.

| Comprobación | Resultado real |
|---|---|
| Linux 6.6.159 ARM64 en WebAssembly JIT y TCI | Ambos aprobados en el navegador con consola VirtIO |
| Programa ARM de 32 bits | Ejecutado, salida 0 |
| Binder, hwbinder y vndbinder | Protocolo 8 en los tres |
| Shim oficial Android memfd/ashmem | Tamaño, protección y rechazo de restaurar escritura verificados en ARM64; compat_ioctl ARM32 también verificado |
| VirtIO RNG | Lectura real de 16 bytes en el navegador |
| Tiempo de la misma prueba de componentes con VirtIO | JIT 17,13 s y TCI 24,53 s; una ejecución por variante, incluye carga/arranque, no mide Android ni rendimiento sostenido |
| Cliente JavaScript y puente ARM64 | Transferencia real de 12 MiB+3 bytes, comparación completa del archivo y validación de CRC |
| Medición de transferencia | 3,48 s en QEMU user de GitHub, **no es una medición del navegador ni una instalación de APK** |
| Android 16 completo | Aún sin validar; último ensayo completado falló y hay otro con el núcleo corregido |
| APK JNI ARM64 y ARM32 | Compilación y firmas v2/v3 verificadas; ejecución en Android aún pendiente |

## Evidencias

- [Resultado JIT con VirtIO](evidence/browser-jit-virtio.json).
- [Resultado TCI con el mismo núcleo y consola](evidence/browser-tci-virtio.json).
- [Página exacta usada para la prueba](../arm64-build/browser-control.html). Requiere los binarios indicados abajo; no es un emulador Android completo.
- [Núcleo con VirtIO console y fuentes](https://github.com/JuanPabloRC3901/mi-android-online/releases/tag/mi-android-arm64-39078667940-1-kernel).
- [Resultado original del navegador](evidence/browser-memory-shim.json).
- [Resultado del transporte JavaScript/ARM64](evidence/serial-transfer.json). El archivo de prueba contiene datos binarios, no un APK ejecutable.
- [Compilación y prueba del núcleo](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/39077455842).
- [Binarios del núcleo y fuentes GPL correspondientes](https://github.com/JuanPabloRC3901/mi-android-online/releases/tag/mi-android-arm64-39077455842-1-kernel).
- [Prueba del puente y comparación del archivo](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/39078264948).
- [Ensayo Android 16 con ese núcleo](https://github.com/JuanPabloRC3901/mi-android-online/actions/runs/39077861745). Consultar result.json: un artefacto publicado no significa que Android haya arrancado.

## Código y reproducción sin instalar herramientas en Windows

Las recetas están en `arm64-build/` y `android16-build/`. Los workflows de `.github/workflows/` compilan en runners públicos estándar efímeros. Los SDK/NDK del runner ya estaban preinstalados. No se instalaron compiladores, Docker, SDK ni emuladores en el PC.

El núcleo base se verifica por SHA256. El componente de memoria proviene de [Android Common, commit e148935a1d484f8a9a0742acbb22ca966f8067df](https://github.com/aosp-mirror/kernel_common/tree/e148935a1d484f8a9a0742acbb22ca966f8067df), con sus avisos GPL conservados e incluidos en las fuentes correspondientes.

La consola PL011 producía caracteres duplicados con JIT. La ruta nueva VirtIO (`virtio-serial-pci` + `virtconsole`, `console=hvc0`) entregó el registro original correcto y pasó los controles completos, sin deduplicar ni reconstruir datos. Esto verifica esa ruta; no demuestra que la causa interna de PL011 esté corregida. TCI también pasó con la misma ruta y sigue disponible como alternativa.

La página de diagnóstico usa las carpetas `jit/runtime/` y `tci/runtime/` extraídas de las compilaciones 39035638452, y `kernel-39078667940/` con `Image` e `initrd.gz` del release de núcleo. Necesita servir esos archivos con JavaScript/WebAssembly, COOP `same-origin` y COEP `require-corp`. La página reserva un heap Wasm de 2 GiB y prueba 768 MiB de RAM invitada; no valida 18 GiB.

El último fallo completado de Android 16 identificó un descriptor de consola heredado por Zygote. El bootstrap ahora usa `O_CLOEXEC` y cierra el descriptor adicional, conservando la validación de Zygote. La repetición todavía está en curso; no se considera arreglado sin su resultado.

Falta completar el arranque Android, verificar los APK y la interacción real con la interfaz, integrar el disco y el puente en el navegador y medir su rendimiento allí. No existe aún una URL pública funcional de esta variante moderna. No hay servidores de emulación alojados en GitHub Actions; sólo compilaciones y pruebas temporales.
