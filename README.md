# iOS26Apps — Tweak Theos para iOS 15 / Dopamine Rootless

## 0. Antes de nada: qué hace y qué NO garantiza este proyecto

- Crea una fila nueva **"Apps y Tweaks"** en la raíz de Ajustes (junto a "General"),
  que abre un panel con dos secciones:
  - 📱 **Aplicaciones**: leídas en vivo con `LSApplicationWorkspace` (icono real vía
    `SBSCopyIconImagePNGDataForDisplayIdentifier`).
  - 🔧 **Tweaks**: leídos en vivo escaneando
    `/var/jb/Library/MobileSubstrate/DynamicLibraries/*.plist` y cruzando esa
    información con `dpkg` (`/var/jb/var/lib/dpkg/status` + `.../dpkg/info/*.list`)
    para obtener nombre bonito, versión, descripción y (si existe) su panel de
    preferencias propio.
- **"Abrir ajustes del tweak"** funciona automáticamente para bundles de
  preferencias generados con la convención estándar de Theos
  (`NombreBundle.bundle` → clase `NombreBundleRootListController`). No es
  100 % universal: algún tweak con una clase raíz nombrada de forma no
  estándar mostrará una alerta en vez de abrirse. Es una limitación real de
  cómo funciona Settings.app, no un bug menor que se pueda "arreglar del todo".
- Tweaks instalados **sin** pasar por `dpkg` (copiados a mano) sí aparecerán
  en la lista (se detectan por el `.plist` de Filter), pero con menos
  metadatos (solo el nombre del archivo).

## 1. Estructura del proyecto

```
iOS26AppsTweak/
├── Makefile
├── control
├── iOS26Apps.plist          # Filter: inyecta el dylib en com.apple.Preferences
├── Tweak/
│   └── Tweak.xm             # Hook a SettingsRootController -specifiers
├── Controllers/
│   ├── ADSAppsRootController.m     # Panel principal (2 secciones)
│   ├── ADSAppDetailController.m    # Detalle de una app
│   └── ADSTweakDetailController.m  # Detalle de un tweak + "Abrir ajustes"
├── Helpers/
│   ├── ADSAppManager.m       # Enumera apps instaladas
│   ├── ADSTweakManager.m     # Detecta tweaks (DynamicLibraries + dpkg)
│   ├── ADSAppInfo.m
│   └── ADSTweakInfo.m
└── Headers/
    ├── Preferences.h                # PSSpecifier / PSListController stubs
    ├── LSApplicationWorkspace.h     # LSApplicationProxy/Workspace stubs
    ├── SpringBoardServices.h        # función de iconos
    ├── ADS*Info.h / ADS*Manager.h / ADS*Controller.h
```

Todos los `.h` en `Headers/` son declaraciones que **tú** compilas dentro de
tu propio tweak (no headers de Apple): son las firmas mínimas necesarias
para poder llamar a esas clases/funciones privadas desde Objective-C sin
warnings ni errores de compilación. Si ya tienes un "headers repo" de
jailbreak con estas mismas clases más completas, puedes sustituir estos
archivos por esos sin cambiar nada más del proyecto.

## 2. Requisitos previos

- macOS o Linux con **Theos** instalado y `$THEOS` exportado.
  - Instalación estándar: https://theos.dev/docs/installation
- SDK de iOS 15 (`iPhoneOS15.5.sdk` o similar) dentro de
  `$THEOS/sdks/`. Si no lo tienes, descarga un SDK pack de theos (hay
  varios repos públicos con SDKs 14–16) y colócalo ahí.
- `ldid` y `dpkg-deb` (Theos los trae o los instala junto con el bootstrap).
- Un iPhone (idealmente 7, arm64) con:
  - Jailbreak **Dopamine** (rootless) sobre iOS 15.x.
  - Acceso SSH (por Wi-Fi o USB con `usbmuxd`/`iproxy`) **o** Filza para
    instalar el `.deb` manualmente.

## 3. Compilar

```bash
cd iOS26AppsTweak
export THEOS=/ruta/a/theos      # si no está ya exportado en tu shell
make clean
make package FINALPACKAGE=1
```

Esto genera un `.deb` dentro de `./packages/`, por ejemplo:
`com.tuusuario.ios26apps_1.0.0_iphoneos-arm64.deb`.

> Antes de compilar, edita:
> - `control`: cambia `com.tuusuario.ios26apps` por tu propio identificador
>   único (evita colisiones con otros tweaks).
> - `Makefile`: revisa que `TARGET = iphone:clang:15.5:15.0` apunte a un SDK
>   que realmente tengas instalado (el número tras los dos puntos es el SDK,
>   el último es el mínimo deployment target).

## 4. Instalar en el iPhone

### Opción A — Instalar directamente por SSH (recomendado durante desarrollo)

En el `Makefile` ya está configurado `after-install` para hacer respring
automático. Solo necesitas la IP del teléfono:

```bash
export THEOS_DEVICE_IP=192.168.1.50   # IP de tu iPhone en la misma red
export THEOS_DEVICE_PORT=22
make package install FINALPACKAGE=1
```

Esto compila, sube el `.deb` por SSH, lo instala con `dpkg -i` dentro del
propio dispositivo y hace respring.

### Opción B — Instalar el `.deb` manualmente

1. Copia el `.deb` generado al iPhone (AirDrop, cable, `scp`, etc.) a
   cualquier ruta accesible por Filza, p. ej. `/var/mobile/Documents/`.
2. Abre **Filza** → navega hasta el archivo → tócalo → **Instalar**.
3. Cuando termine, haz respring (Filza lo ofrece automáticamente, o desde
   el propio gestor de paquetes: Sileo/Zebra → "Respring").

### Opción C — Vía Sileo/Zebra con un repo local

Si prefieres distribuirlo como si fuera un repo, sube el `.deb` a una
carpeta servida por un servidor HTTP simple (`python3 -m http.server`) y
añade esa URL como fuente en Sileo/Zebra.

## 5. Verificar que funciona

1. Abre **Ajustes**.
2. Debajo de "General" debería aparecer la fila **"Apps y Tweaks"**.
3. Ábrela: deberías ver las secciones 📱 Aplicaciones y 🔧 Tweaks pobladas
   automáticamente.
4. Toca una app → deberías ver Bundle ID, versión, tipo, y poder abrirla.
5. Toca un tweak → deberías ver su información y, si tiene panel propio,
   el botón "Abrir ajustes del tweak".

## 6. Problemas comunes en Rootless / Dopamine

| Síntoma | Causa probable | Solución |
|---|---|---|
| El `.deb` no compila: `SDK not found` | Falta el SDK de iOS 15 en `$THEOS/sdks` | Descarga un SDK pack y colócalo ahí, o ajusta el número de SDK en `TARGET` al que sí tengas |
| Compila pero `dpkg -i` falla en el teléfono | Falta `Depends` reales (libhooker/mobilesubstrate) o arquitectura mal puesta | Revisa `control`: `Architecture: iphoneos-arm64`, y que el sustrato (libhooker/Substrate) esté realmente instalado |
| Se instala pero **no aparece** la fila en Ajustes | El `.plist` de Filter no coincide con el bundle id de Settings, o no se hizo respring de verdad | Confirma que `iOS26Apps.plist` contenga `com.apple.Preferences`; fuerza `killall -9 Preferences` y vuelve a abrir Ajustes desde cero (no solo cambiar de pestaña) |
| Aparece la fila pero al tocarla **crashea** Ajustes | Símbolo `PSSpecifier`/`PSListController` no resuelto en tiempo de ejecución (headers incompletos) o el SDK usado no tiene Preferences.framework enlazado correctamente | Revisa el crash log (`/var/mobile/Library/Logs/CrashReporter` o vía SSH `sysdiagnose`), casi siempre apunta a un mensaje enviado a `nil`/selector no reconocido; añade el método que falte a `Headers/Preferences.h` |
| La lista de Tweaks sale **vacía** | La ruta rootless no es exactamente `/var/jb` en tu jailbreak, o no hay tweaks vía dpkg | Comprueba por SSH: `ls /var/jb/Library/MobileSubstrate/DynamicLibraries/`; si tu ruta base es distinta, cambia `kRootlessBase`/`kDylibsDir`/`kDpkgStatusPath`/`kDpkgInfoDir` en `ADSTweakManager.m` |
| Los iconos de apps no cargan | `SpringBoardServices.framework` no está en el `LinkerAncestor`/no se resolvió la función en tiempo de ejecución | Confirma que el framework existe en el dispositivo (`find / -iname "SpringBoardServices*"` por SSH) y que `dlopen`/enlace dinámico no falla (revisa el log de crash) |
| "Abrir ajustes del tweak" muestra la alerta de error siempre | El bundle de ese tweak no sigue la convención `<Nombre>RootListController` | Es una limitación conocida (ver sección 0); puedes añadir manualmente el nombre real de la clase de ese tweak en `openTweakPreferences` como caso especial si lo necesitas para un tweak concreto |

## 7. Depurar en vivo

Desde tu Mac/Linux con el iPhone en la misma red (o USB + `iproxy`):

```bash
# Ver logs en tiempo real de Settings/Preferences
ssh mobile@<IP-IPHONE> "log stream --predicate 'process == \"Preferences\"'"
```

Ahí verás cualquier `NSLog`/crash relacionado con tu hook en cuanto abras
Ajustes o entres al panel nuevo.

## 8. Siguientes pasos razonables (no incluidos para no complicar la v1)

- Icono propio para la fila en la raíz de Ajustes (`iconImage` en el
  `PSSpecifier`, apuntando a un `.png` en `/var/jb/Library/Application
  Support/iOS26Apps/`).
- Caché de iconos en disco para no recalcular en cada apertura.
- Botón para desinstalar/activar-desactivar un tweak directamente desde el
  detalle (requiere invocar dpkg/apt desde el proceso de Settings, lo cual
  necesita privilegios y hay que hacerlo con cuidado para no dejar el
  sistema de paquetes en un estado inconsistente).
