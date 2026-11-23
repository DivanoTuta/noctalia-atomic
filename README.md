# Noctalia Atomic (BlueBuild)

Imagen personalizada de **Fedora Atomic** basada en **Universal Blue (`ghcr.io/ublue-os/base-main`)** con escritorio Wayland completo listo para usar:

- **Compositor Wayland:** [Niri](https://github.com/niri-wm/niri) (*scrollable tiling* con bordes redondeados, desenfoque *blur* nativo en Noctalia y Alacritty, fondo desenfocado en *Overview*, `xwayland-satellite` para apps X11 y reglas flotantes ergonómicas).
- **Desktop Shell:** [Noctalia Shell](https://noctalia.dev) (barra, dock, lanzador, centro de control, OSD nativo de volumen, micrófono y brillo, control multimedia MPRIS, búsqueda directa al escribir en *Overview*, agente Polkit integrado, pantalla de bloqueo con soporte biométrico `fprintd`, anotación de capturas, notificaciones, widgets y temas dinámicos).
- **Display Manager / Greeter:** `greetd` + [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) sincronizado con el fondo, tema y avatar del usuario (`accountsservice`).
- **Terminal y Shell:** `alacritty` + `fish` (con fuentes *JetBrains Mono Nerd Font*, `btop`, `fastfetch`, `ripgrep`, `jq`, `yq` y `wl-clipboard`).
- **Navegación y Ofimática:** `Firefox`, `LibreOffice` (con fuentes métricas compatibles con MS Office: *Carlito* y *Caladea*), `Text Editor` (GTK4), `Calculadora` y `Papers` (PDFs y documentos).
- **Desarrollo:** Visual Studio Code nativo + `distrobox` y `podman-compose` (entornos reproducibles sin tocar el sistema base).
- **Gaming:** Steam nativo con reglas de mandos (`steam-devices`) y overlay `mangohud`.
- **Gestión de aplicaciones:** `Bazaar` (tienda moderna), `Warehouse` (limpieza y versiones) y `Flatseal` (permisos de Flatpak).
- **Herramientas del Sistema, Hardware, Red e Impresión:** `Mission Center` (monitor de recursos, GPU, red por proceso con `nethogs` y consumo eléctrico RAPL), `Baobab` (espacio en disco), `Discos` (`gnome-disk-utility`), `GParted` (particionado avanzado con soporte `exfatprogs`, `ntfs-3g`/`ntfsprogs` y `dosfstools`, y `mate-polkit` como proveedor ligero de `PolicyKit-authentication-agent`), `File Roller` (comprimidos con `7zip`, `unrar`, `unar` y `unzip`), `Blueman` (Bluetooth bajo demanda vía D-Bus, con autostart enmascarado para no duplicar el widget de Noctalia), `pavucontrol` (audio), `nm-connection-editor` + `nm-connection-editor-desktop` (red y WireGuard), `CUPS` + `Avahi`/`nss-mdns` + `system-config-printer` (impresión en red e IPP/USB), `bolt` (docks Thunderbolt/USB4), `pciutils` (`lspci`) y `usbutils` (`lsusb`), `Seahorse` + `oo7` (`oo7-daemon`, `oo7-portal`, `pam_oo7` como llavero de secretos moderno en Rust), `lm_sensors` (temperaturas), `powertop` (diagnóstico de consumo energético), `brightnessctl` y `ddcutil` (brillo de monitores).
- **Multimedia y Grabación:** `Kooha` (grabador de pantalla y audio GTK4), `Celluloid` (reproductor principal GTK/mpv), `VLC` (reproductor universal) y `Loupe` (visor de imágenes).
- **Archivos:** `Nautilus` con previsualización rápida `sushi`, miniaturas de vídeo `ffmpegthumbnailer`, menú contextual (*«Abrir en Alacritty»* y *«Enviar por Bluetooth»*) y soporte nativo para dispositivos USB Android/iOS (`gvfs-mtp`, `gvfs-afc`, `gvfs-gphoto2`) y carpetas en red (`gvfs-smb`, `gvfs-nfs`).
- **Dotfiles preconfigurados en `/etc/skel`:** Configuración lista para nuevos usuarios de Niri (teclado `es`, reglas flotantes y atajos adaptados a distribución española), Noctalia (bloqueo automático tras 10 min de inactividad, apagado de pantalla a los 11 min —o 30 s tras bloquear—, escala `ui_scale = 1.25` y `auto_locate = true`, personalizables desde Ajustes), Alacritty, `btop`, Fish, temas GTK 3/4 (`adw-gtk3-dark` y `Papirus-Dark` por defecto) y overrides globales de Flatpak.
- **Mantenimiento del Sistema:** Integración directa con el actualizador nativo de Universal Blue (`ujust update`, accesible desde el lanzador como **Actualizar Sistema** o con el alias `update` en Fish), actualizaciones automáticas en segundo plano (`rpm-ostreed-automatic.timer`) y utilidades `ujust` para firmware (`fwupd`), *changelogs* y limpieza.

---

## Estructura del Proyecto

- `recipes/recipe.yml`: Receta principal de BlueBuild (módulos `dnf`, `files`, `script`, `fonts`, `default-flatpaks`, `systemd`, `signing`).
- `files/dnf/`: Definiciones de repositorios externos (`lionheartp-Hyprland.repo` restringido a `noctalia-greeter*` y `vscode.repo` restringido a `code`).
- `files/system/etc/greetd/config.toml`: Configuración de `greetd` apuntando al wrapper de `noctalia-greeter-session`.
- `files/system/usr/libexec/noctalia-greeter-wrapper.sh`: Wrapper de `noctalia-greeter-session` con detección automática de VMware (`vmwgfx`).
- `files/system/usr/share/noctalia-atomic/greeter.toml` y `files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf`: Configuración declarativa del greeter aplicada en cada arranque (`C+`) sobre `/var/lib/noctalia-greeter/greeter.toml`.
- `files/system/usr/share/noctalia-atomic/mountain.jpg`: Avatar de usuario por defecto (`512×512`) configurado en Noctalia y sincronizado con `noctalia-greeter` mediante `accountsservice`.
- `files/system/usr/lib/systemd/system/greetd.service.d/override.conf`: Drop-in de `greetd.service` (orden de arranque tras Plymouth, fallback a `getty@tty1` y etiquetado SELinux).
- `files/system/usr/lib/systemd/user-environment-generators/10-noctalia-graphics.sh`: Generador de entorno que selecciona Vulkan/OpenGL y ajusta cursor DRM y *blur* en Niri según hardware real o máquina virtual.
- `files/system/usr/lib/environment.d/10-noctalia-atomic.conf`: Variables de entorno globales de sesión (`ELECTRON_OZONE_PLATFORM_HINT=auto`).
- `files/system/usr/lib/udev/rules.d/`: Reglas `udev` para sensores de energía RAPL (`99-powercap.rules`) y discos NVMe virtuales de VMware (`99-vmware-nvme.rules`).
- `files/system/usr/share/dbus-1/services/org.freedesktop.secrets.service` y `files/system/usr/share/xdg-desktop-portal/niri-portals.conf`: Activación D-Bus y portal de secretos XDG configurados para `oo7-daemon` / `oo7-portal`.
- `files/system/usr/share/glib-2.0/schemas/99-noctalia-atomic.gschema.override`: Override global de GSettings que fija `Papirus-Dark` como tema de iconos y `adw-gtk3-dark` (`prefer-dark`) como tema GTK por defecto.
- `files/system/usr/share/polkit-1/rules.d/49-noctalia-greeter-sync.rules`: Regla Polkit restringida al grupo `wheel` para sincronizar la apariencia de Noctalia con `noctalia-greeter` sin pedir contraseña.
- `files/system/usr/share/applications/system-update.desktop`: Entrada en el lanzador que ejecuta `ujust update` en una ventana flotante de Alacritty con aviso final para cerrar con `Enter`.
- `files/system/usr/share/nautilus-python/extensions/open-alacritty.py`: Extensión de Nautilus para abrir carpetas locales en Alacritty.
- `files/system/etc/skel/`: Dotfiles por defecto para nuevos usuarios (`niri`, `noctalia`, `alacritty`, `btop`, `fish`, `gtk-3.0`, `gtk-4.0` y `.local/share/flatpak/overrides/global`).
- `files/system/usr/share/backgrounds/noctalia/`: Fondo de pantalla preinstalado.
- `.editorconfig`: Reglas de formato compartidas para scripts shell (`shfmt` y editores).
- `cosign.pub`: Clave pública de verificación de firma de la imagen.
- `.github/workflows/build.yml`: Pipeline de GitHub Actions que valida receta, scripts (`files/` y snippets de `recipe.yml`), archivos `.desktop`, archivos TOML (`tomllib`) y Python (`ruff`/`mypy`), y compila/publica la imagen en GHCR (`ghcr.io/<tu-usuario>/noctalia-atomic`).

---

## Opciones de Compilación y Despliegue

### Opción A: Compilación automática en la nube (GitHub Actions + GHCR) — *Recomendado*

Compila la imagen en servidores de GitHub sin consumir recursos locales y la publica firmada en GitHub Container Registry:

1. Haz fork o sube este repositorio a GitHub (recomendado como repositorio público para almacenamiento y transferencia gratuitos en GHCR).
2. Genera tu par de claves de firma de contenedores con `cosign` (**sin contraseña**, requisito de `blue-build/github-action`):
   ```bash
   podman run --rm -it --user 0:0 --security-opt label=disable \
     -e COSIGN_PASSWORD="" -v "$PWD":/workspace -w /workspace \
     ghcr.io/sigstore/cosign/cosign:latest generate-key-pair
   ```
3. Guarda el contenido de `cosign.key` (nunca la subas a Git) en los **GitHub Secrets** del repositorio con el nombre `SIGNING_SECRET`, y sube tu `cosign.pub` al repositorio.
4. Tras finalizar el primer workflow en GitHub Actions, verifica en la página del repositorio (**Packages → `noctalia-atomic` → Package settings**) que la visibilidad del paquete en GHCR esté en **Public** (para evitar errores `401 Unauthorized`), y cambia a tu imagen desde cualquier equipo con Fedora Atomic:
   ```bash
   sudo bootc switch ghcr.io/<tu-usuario>/noctalia-atomic:latest
   systemctl reboot
   ```

---

### Opción B: Compilación directa en local (sin GitHub)

Puedes construir la imagen directamente en tu equipo con Podman y BlueBuild CLI, almacenándola en el *storage* local de contenedores:

#### 1. Instalar BlueBuild CLI
Extrae el binario oficial desde la imagen `ghcr.io/blue-build/cli:latest-installer`:
```bash
container_id="$(podman create --pull always ghcr.io/blue-build/cli:latest-installer)"
podman cp "${container_id}:/out/bluebuild" /tmp/bluebuild
podman rm "${container_id}"
sudo install -m 0755 /tmp/bluebuild /usr/local/bin/bluebuild
rm -f /tmp/bluebuild
```

#### 2. Compilar la imagen
Desde la raíz del proyecto:
```bash
bluebuild build ./recipes/recipe.yml
```
> [!NOTE]
> La compilación local requiere aproximadamente 20-25 GB de espacio libre temporal en disco y al menos 4-6 GB de RAM disponibles. La imagen resultante queda registrada en el almacenamiento local de Podman como `localhost/noctalia-atomic:latest`.

#### 3. Aplicar la imagen compilada y reiniciar
```bash
# Con bootc:
sudo bootc switch --transport containers-storage localhost/noctalia-atomic:latest

# O con rpm-ostree:
# sudo rpm-ostree rebase ostree-unverified-image:containers-storage:localhost/noctalia-atomic:latest

systemctl reboot
```

---

## Instalación Limpia mediante ISO

Si quieres instalar **Noctalia Atomic** desde cero (en un equipo nuevo o en una máquina virtual) en lugar de hacer *rebase* sobre una instalación previa de Fedora Atomic, puedes generar una ISO instaladora a partir de tu imagen publicada en GHCR.

### 1. Generar la ISO con BlueBuild

Requiere [BlueBuild CLI](#1-instalar-bluebuild-cli) y Podman:

```bash
bluebuild generate-iso \
  --variant kinoite \
  --iso-name noctalia-atomic.iso \
  -o ./iso-out \
  image ghcr.io/<tu-usuario>/noctalia-atomic:latest
```

> [!NOTE]
> Si `/tmp` tiene poco espacio disponible, añade `--tempdir /ruta/con/espacio` al comando anterior.

### 2. Instalar activando la creación de usuario (`inst.profile=fedora-sericea`)

> [!IMPORTANT]
> A partir de Fedora 44/45, el perfil de Anaconda `fedora-kinoite` oculta las pantallas de creación de usuario y contraseña porque delega ese paso en `plasma-setup` (que esta imagen no incluye). Si instalas con el perfil por defecto, el sistema arrancará sin usuarios creados y no podrás iniciar sesión en `noctalia-greeter`.

Al arrancar el equipo o la VM desde `noctalia-atomic.iso`:

1. En el menú de arranque (**GRUB**) del instalador, selecciona la entrada de instalación y pulsa **`e`**.
2. Al final de la línea que empieza por `linux`, añade:
   ```text
   inst.profile=fedora-sericea
   ```
   *(En GRUB el teclado usa distribución inglesa US; en un teclado físico español, `=` está en la tecla `¡` `¿` a la izquierda de Retroceso y `-` en la tecla `'` `?` a la derecha del `0`.)*
3. Pulsa **`Ctrl+X`** (o **`F10`**) para iniciar el instalador.
4. En la pantalla de cuentas de Anaconda:
   - Crea tu usuario y marca **«Hacer administrador a este usuario»** (añade la cuenta al grupo `wheel`, necesario para `sudo` y para los permisos locales descritos en [Seguridad y Permisos Locales](#seguridad-y-permisos-locales)).
   - Deja la cuenta **`root` deshabilitada** (configuración recomendada en Fedora Atomic).

El perfil `fedora-sericea` hereda del perfil base `fedora` (muestra la creación de usuario y contraseña en Anaconda) y conserva el particionado **Btrfs** de Fedora Atomic (`/`, `/home` y `/var` con compresión `zstd:1`).

### Alternativa: generar una ISO que pida usuario por defecto (sin editar GRUB)

Por debajo, `bluebuild generate-iso` ejecuta el contenedor `ghcr.io/jasonn3/build-container-installer:v1.5.0`, pero no expone ninguna opción para añadir parámetros al menú de arranque de la ISO. Si prefieres obtener una ISO lista para arrancar e instalar sin editar GRUB a mano, puedes lanzar ese mismo contenedor directamente con `EXTRA_BOOT_PARAMS="inst.profile=fedora-sericea"`, que graba el parámetro en el `grub.cfg` (BIOS y UEFI) de la propia ISO:

```bash
mkdir -p ./iso-out ./dnf-cache

sudo podman run --rm --privileged \
  --network=host \
  --security-opt label=disable \
  -v "$PWD/iso-out:/build-container-installer/build" \
  -v "$PWD/dnf-cache:/cache/dnf" \
  ghcr.io/jasonn3/build-container-installer:v1.5.0 \
  VARIANT=Kinoite \
  VERSION=45 \
  IMAGE_REPO=ghcr.io/<tu-usuario> \
  IMAGE_NAME=noctalia-atomic \
  IMAGE_TAG=latest \
  ISO_NAME=build/noctalia-atomic.iso \
  DNF_CACHE=/cache/dnf \
  SECURE_BOOT_KEY_URL=https://github.com/ublue-os/bazzite/raw/main/secure_boot.der \
  ENROLLMENT_PASSWORD=universalblue \
  WEB_UI=false \
  EXTRA_BOOT_PARAMS="inst.profile=fedora-sericea"
```

- `--privileged` y `--security-opt label=disable`: necesarios para que `lorax` monte dispositivos *loop* al generar el instalador.
- `--network=host`: reutiliza la red y DNS del equipo anfitrión (evita errores de resolución DNS dentro del contenedor en redes con DNS local o `systemd-resolved`).
- `-v .../build` y `-v .../dnf`: carpetas locales para la ISO resultante y la caché de paquetes DNF.
- `SECURE_BOOT_KEY_URL` y `ENROLLMENT_PASSWORD`: clave MOK pública de Universal Blue (`universalblue`), igual que añade `bluebuild` por defecto.
- `EXTRA_BOOT_PARAMS`: deja `inst.profile=fedora-sericea` fijado en el arranque de la ISO (creación de usuario + Btrfs Atomic).

> [!NOTE]
> Ajusta `VERSION` si tu imagen está basada en una versión de Fedora distinta de la 45.

---

## Primeros Pasos tras Instalar o Hacer Rebase

### 1. Usuarios existentes (migración de dotfiles desde `/etc/skel`)
> [!IMPORTANT]
> Los archivos de `/etc/skel` solo se copian automáticamente al crear **usuarios nuevos**. Si has hecho rebase desde una instalación previa de Fedora Atomic con tu carpeta personal ya existente, copia los dotfiles base sin sobrescribir tus archivos previos:
> ```bash
> cp -r --update=none /etc/skel/. ~/
> ```
> Ten en cuenta que `--update=none` solo copia ficheros que aún no existan en tu `$HOME`; si una actualización futura modifica un archivo que ya tenías (por ejemplo `~/.config/niri/config.kdl`), deberás copiarlo o fusionarlo manualmente desde `/etc/skel`.

### 2. Actualizar el sistema y utilidades `ujust`
La imagen base `ublue-os/base-main` trae activadas por defecto las **actualizaciones automáticas en segundo plano** (`rpm-ostreed-automatic.timer` con política `stage`), por lo que si el sistema apunta a un registro remoto (como GHCR) las capas nuevas se descargan solas y se aplican en el siguiente reinicio.

Cuando quieras actualizar manualmente al momento, abre **Actualizar Sistema** desde el lanzador (`Mod+D`) o ejecuta `update` (`ujust update`), que actualiza en secuencia la imagen base (`rpm-ostree update`), los Flatpaks (`flatpak update -y`) y los contenedores `distrobox`. Puedes consultar todas las recetas disponibles en tu versión con `ujust --choose`; entre las más útiles incluidas de serie destacan:
- `ujust toggle-updates`: activar o desactivar las actualizaciones automáticas en segundo plano.
- `ujust changelogs`: ver qué paquetes del sistema base han cambiado en la última actualización.
- `ujust update-firmware`: buscar y aplicar actualizaciones de BIOS/UEFI y hardware mediante `fwupd`.
- `ujust clean-system`: limpiar capas antiguas de `rpm-ostree`, Flatpak y Podman.
- `ujust setup-luks-tpm-unlock`: configurar desbloqueo automático del disco cifrado LUKS mediante TPM 2.0 (ideal en portátiles como Lenovo ThinkPad).

### 3. Configurar el lector de huellas (`fprintd`)
1. Registra tu huella desde una terminal:
   ```bash
   fprintd-enroll
   ```
2. Si actualizaste desde un sistema existente cuyo `/etc/authselect` tenía cambios locales, asegúrate de tener habilitado el perfil biométrico:
   ```bash
   sudo authselect enable-feature with-fingerprint
   ```
> [!NOTE]
> - `greeter.toml` habilita `allow_empty_password = true` para poder pulsar **Enter** con el campo vacío e iniciar la lectura biométrica en `greetd`. Debido a cómo serializa PAM los módulos en Fedora (`pam_fprintd` antes de `pam_unix`), mientras se espera la huella el inicio con contraseña queda en espera hasta que la lectura finalice o expire su *timeout*.
> - Al iniciar sesión mediante huella en `greetd`, PAM no recibe tu contraseña en claro y no puede descifrar automáticamente el llavero (`oo7-daemon`). Si usas cifrado de disco completo (LUKS) y prefieres evitar el aviso del llavero, puedes gestionar su contraseña desde **Seahorse**.

### 4. Atajos de teclado esenciales (Niri)

En sesión normal, `Mod` equivale a la tecla `Super` (Windows). Los atajos están adaptados a distribución de teclado español (`es`):

| Atajo | Acción |
| :--- | :--- |
| `Mod + D` | Abrir lanzador de aplicaciones (Noctalia) |
| `Mod + S` | Abrir centro de control (Noctalia) |
| `Mod + Shift + ,` | Abrir ajustes (Noctalia) |
| `Mod + T` | Abrir terminal (Alacritty) |
| `Mod + E` | Abrir gestor de archivos (Nautilus) |
| `Mod + Q` | Cerrar ventana activa |
| `Mod + F` / `Mod + Shift + F` | Maximizar columna / Pantalla completa |
| `Mod + -` / `Mod + +` | Reducir / ampliar ancho de columna (`-10%` / `+10%`) |
| `Mod + Alt + ←` / `Mod + Alt + →` | Integrar o expulsar ventana hacia la columna izquierda / derecha |
| `Mod + V` | Alternar ventana flotante |
| `Mod + O` | Vista general (*Overview*) |
| `Print` / `Ctrl + Print` / `Alt + Print` | Captura de área / pantalla / ventana (`~/Imágenes/Capturas/`) |
| `Shift + Print` | Capturar y anotar (Noctalia) |
| `Super + Alt + L` | Bloquear pantalla (Noctalia) |
| `Mod + F1` | Mostrar ayuda interactiva con todos los atajos |

---

## Seguridad y Permisos Locales

Para habilitar métricas avanzadas de **Mission Center** y la sincronización fluida del greeter sin otorgar permisos globales ni ejecutar aplicaciones completas como `root`, la imagen aplica tres ajustes restringidos **exclusivamente al grupo `wheel`** (usuarios administradores en Fedora):

- **Tráfico de red por proceso (`nethogs`):** se aplican las *capabilities* recomendadas por Mission Center (`cap_net_admin,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+pe`), pero el binario queda con permisos `0750 root:wheel` para impedir su ejecución por cuentas de servicio o usuarios sin privilegios.
- **Consumo eléctrico de CPU (RAPL):** la regla `99-powercap.rules` otorga permisos `0440 root:wheel` sobre `/sys/.../intel-rapl*/energy_uj`. Limitar la lectura al grupo `wheel` evita exponer el contador a todo el sistema y reduce la superficie del ataque de canal lateral PLATYPUS (CVE-2020-8694).
- **Sincronización automática de `noctalia-greeter`:** la regla Polkit `49-noctalia-greeter-sync.rules` autoriza sin contraseña la acción acotada `org.noctalia.greeter.sync-appearance` (`/usr/bin/noctalia-greeter-apply-appearance`) únicamente para sesiones locales activas de usuarios en `wheel`. El resto de cuentas mantienen la petición estándar de contraseña de administrador.

---

## Compatibilidad con Máquinas Virtuales (VMware y otras VMs)

- **Aceleración Gráfica y Cursor DRM Dinámicos:** el generador de entorno `10-noctalia-graphics.sh` detecta automáticamente si el sistema se ejecuta en hardware real o virtualizado:
  - **Hardware real (Intel, AMD o NVIDIA):** GTK4/Libadwaita y Flatpaks usan **Vulkan** de forma nativa, y Niri mantiene activos el **plano de cursor DRM por hardware** y el **blur nativo**.
  - **Máquinas virtuales (VMware, VirtualBox, QEMU/KVM):** se exporta `GSK_RENDERER=gl` (evitando la emulación por CPU *Lavapipe*) y se genera `~/.cache/niri-vm-quirks.kdl` con `disable-cursor-plane` y `blur { off }` para mantener la fluidez.
  - **Pantalla de login (`greetd`):** el wrapper `/usr/libexec/noctalia-greeter-wrapper.sh` detecta `vmwgfx` (VMware) para activar renderizado por software (`pixman`) y desactivar KMS atómico (`WLR_DRM_NO_ATOMIC=1`), evitando errores de `dma-buf` y commits atómicos `-EBUSY`.
- **Discos Virtuales NVMe (VMware):** la regla `99-vmware-nvme.rules` detecta el controlador NVMe virtual de VMware (`0x15ad:0x07f0`) y ajusta `io_timeout=2000` (2 s) y `nr_requests=64` para evitar bloqueos de 30 s por pérdida de interrupciones MSI-X. Adicionalmente, en VMware se recomienda desactivar APST en los argumentos del kernel:
  ```bash
  sudo rpm-ostree kargs --append-if-missing=nvme_core.default_ps_max_latency_us=0
  ```
