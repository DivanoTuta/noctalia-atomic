# Noctalia Atomic (BlueBuild)

Imagen personalizada de **Fedora Atomic** basada en **Universal Blue (`ghcr.io/ublue-os/base-main`)** con escritorio Wayland completo listo para usar:

- **Compositor Wayland:** [Niri](https://github.com/niri-wm/niri) (*scrollable tiling* con bordes redondeados, desenfoque *blur* nativo en Noctalia y Alacritty, fondo desenfocado en *Overview*, `xwayland-satellite` para apps X11 y reglas flotantes ergonómicas).
- **Desktop Shell:** [Noctalia Shell](https://noctalia.dev) (barra, dock, lanzador, centro de control, OSD nativo de volumen y brillo, búsqueda directa al escribir en *Overview*, agente Polkit integrado, pantalla de bloqueo con soporte biométrico `fprintd`, anotación de capturas, notificaciones, widgets y temas dinámicos).
- **Display Manager / Greeter:** `greetd` + [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) sincronizado con el fondo y tema del escritorio.
- **Terminal y Shell:** `alacritty` + `fish` (con fuentes *JetBrains Mono Nerd Font*, `btop`, `fastfetch` y `wl-clipboard`).
- **Navegación y Ofimática:** `Firefox`, `LibreOffice` (con fuentes métricas compatibles con MS Office: *Carlito* y *Caladea*), `Text Editor` (GTK4), `Calculadora` y `Papers` (PDFs y documentos).
- **Desarrollo:** Visual Studio Code nativo + `distrobox` (entornos reproducibles sin tocar el sistema base).
- **Gaming:** Steam nativo con reglas de mandos (`steam-devices`) y overlay `mangohud`.
- **Gestión de aplicaciones:** `Bazaar` (tienda moderna), `Warehouse` (limpieza y versiones) y `Flatseal` (permisos de Flatpak).
- **Herramientas del Sistema, Hardware y Red:** `Mission Center` (monitor de recursos, GPU, red por proceso con `nethogs` y consumo eléctrico RAPL), `Baobab` (espacio en disco), `Discos` (`gnome-disk-utility`), `File Roller` (comprimidos), `Blueman` (Bluetooth), `pavucontrol` (audio), `nm-connection-editor` (red), `Seahorse` + `gnome-keyring` (llavero de claves), `lm_sensors` (temperaturas), `brightnessctl` y `ddcutil` (brillo de monitores).
- **Multimedia y Grabación:** `Kooha` (grabador de pantalla y audio GTK4), `Celluloid` (reproductor principal GTK/mpv), `VLC` (reproductor universal) y `Loupe` (visor de imágenes).
- **Archivos:** `Nautilus` con previsualización rápida `sushi`, miniaturas de vídeo `ffmpegthumbnailer`, menú contextual (*«Abrir en Alacritty»* y *«Enviar por Bluetooth»*) y soporte nativo para dispositivos USB Android/iOS (`gvfs-mtp`, `gvfs-afc`, `gvfs-gphoto2`) y carpetas en red (`gvfs-smb`, `gvfs-nfs`).
- **Dotfiles preconfigurados en `/etc/skel`:** Configuración lista para nuevos usuarios de Niri (teclado `es`, reglas flotantes y atajos en español), Noctalia (bloqueo automático tras 10 min de inactividad), Alacritty, Fish, temas GTK 3/4 y overrides globales de Flatpak.
- **Mantenimiento del Sistema:** Integración directa con el actualizador nativo de Universal Blue (`ujust update`, accesible desde el lanzador como **Actualizar Sistema** o con el alias `update` en Fish), actualizaciones automáticas en segundo plano (`rpm-ostreed-automatic.timer`) y utilidades `ujust` para firmware (`fwupd`), *changelogs* y limpieza.

---

## Estructura del Proyecto

- `recipes/recipe.yml`: Receta principal de BlueBuild (módulos `dnf`, `files`, `script`, `fonts`, `default-flatpaks`, `systemd`, `signing`).
- `files/dnf/`: Definiciones de repositorios externos (`lionheartp-Hyprland.repo` restringido a `noctalia-greeter*` y `vscode.repo`).
- `files/system/etc/greetd/config.toml`: Configuración de `greetd` apuntando al wrapper de `noctalia-greeter-session`.
- `files/system/usr/libexec/noctalia-greeter-wrapper.sh`: Wrapper de `noctalia-greeter-session` con detección automática de VMware (`vmwgfx`).
- `files/system/usr/share/noctalia-atomic/greeter.toml` y `files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf`: Configuración declarativa del greeter aplicada en cada arranque (`C+`) sobre `/var/lib/noctalia-greeter/greeter.toml`.
- `files/system/usr/lib/systemd/system/greetd.service.d/override.conf`: Drop-in de `greetd.service` (orden de arranque tras Plymouth, fallback a `getty@tty1` y etiquetado SELinux).
- `files/system/usr/lib/systemd/user-environment-generators/10-noctalia-graphics.sh`: Generador de entorno que selecciona Vulkan/OpenGL y ajusta cursor DRM y *blur* en Niri según hardware real o máquina virtual.
- `files/system/usr/lib/environment.d/10-noctalia-atomic.conf`: Variables de entorno globales de sesión (`ELECTRON_OZONE_PLATFORM_HINT=auto`).
- `files/system/usr/lib/udev/rules.d/`: Reglas `udev` para sensores de energía RAPL (`99-powercap.rules`) y discos NVMe virtuales de VMware (`99-vmware-nvme.rules`).
- `files/system/usr/share/applications/system-update.desktop`: Entrada en el lanzador que ejecuta `ujust update` en una ventana flotante de Alacritty (`alacritty --hold`).
- `files/system/usr/share/nautilus-python/extensions/open-alacritty.py`: Extensión de Nautilus para abrir carpetas locales en Alacritty.
- `files/system/etc/skel/`: Dotfiles por defecto para nuevos usuarios (`niri`, `noctalia`, `alacritty`, `fish`, `gtk-3.0`, `gtk-4.0` y `.local/share/flatpak/overrides/global`).
- `files/system/usr/share/backgrounds/noctalia/`: Fondos de pantalla preinstalados.
- `cosign.pub`: Clave pública de verificación de firma de la imagen.
- `.github/workflows/build.yml`: Pipeline de GitHub Actions que valida receta/scripts y compila/publica la imagen en GHCR (`ghcr.io/<tu-usuario>/noctalia-atomic`).

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

## Primeros Pasos tras Instalar o Hacer Rebase

### 1. Usuarios existentes (migración de dotfiles desde `/etc/skel`)
> [!IMPORTANT]
> Los archivos de `/etc/skel` solo se copian automáticamente al crear **usuarios nuevos**. Si has hecho rebase desde una instalación previa de Fedora Atomic con tu carpeta personal ya existente, copia los dotfiles base sin sobrescribir tus archivos previos:
> ```bash
> cp -rn /etc/skel/. ~/
> ```

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
> Al iniciar sesión mediante huella en `greetd`, PAM no recibe tu contraseña en claro y no puede descifrar automáticamente el llavero `gnome-keyring`. Si usas cifrado de disco completo (LUKS) y prefieres evitar el aviso del llavero, puedes gestionar su contraseña desde **Seahorse**.

### 4. Atajos de teclado esenciales (Niri)

| Atajo | Acción |
| :--- | :--- |
| `Mod + D` | Abrir lanzador de aplicaciones (Noctalia) |
| `Mod + S` | Abrir centro de control (Noctalia) |
| `Mod + Shift + ,` | Abrir ajustes (Noctalia) |
| `Mod + T` | Abrir terminal (Alacritty) |
| `Mod + E` | Abrir gestor de archivos (Nautilus) |
| `Mod + Q` | Cerrar ventana activa |
| `Mod + F` / `Mod + Shift + F` | Maximizar columna / Pantalla completa |
| `Mod + V` | Alternar ventana flotante |
| `Mod + O` | Vista general (*Overview*) |
| `Print` / `Ctrl + Print` / `Alt + Print` | Captura de área / pantalla / ventana (`~/Imágenes/Capturas/`) |
| `Shift + Print` | Capturar y anotar (Noctalia) |
| `Super + Alt + L` | Bloquear pantalla (Noctalia) |
| `Mod + Shift + /` | Mostrar ayuda interactiva con todos los atajos |

---

## Seguridad y Permisos Locales

Para que **Mission Center** pueda mostrar métricas avanzadas sin ejecutar toda la aplicación como `root`, la imagen aplica dos ajustes restringidos **exclusivamente al grupo `wheel`** (usuarios administradores en Fedora):

- **Tráfico de red por proceso (`nethogs`):** se aplican las *capabilities* recomendadas por Mission Center (`cap_net_admin,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+pe`), pero el binario queda con permisos `0750 root:wheel` para impedir su ejecución por cuentas de servicio o usuarios sin privilegios.
- **Consumo eléctrico de CPU (RAPL):** la regla `99-powercap.rules` otorga permisos `0440 root:wheel` sobre `/sys/.../intel-rapl:*/energy_uj`. Limitar la lectura al grupo `wheel` evita exponer el contador a todo el sistema y reduce la superficie del ataque de canal lateral PLATYPUS (CVE-2020-8694).

---

## Compatibilidad con Máquinas Virtuales (VMware y otras VMs)

- **Aceleración Gráfica y Cursor DRM Dinámicos:** el generador de entorno `10-noctalia-graphics.sh` detecta automáticamente si el sistema se ejecuta en hardware real o virtualizado:
  - **Hardware real (Intel, AMD o NVIDIA):** GTK4/Libadwaita y Flatpaks usan **Vulkan** de forma nativa, y Niri mantiene activos el **plano de cursor DRM por hardware** y el **blur nativo**.
  - **Máquinas virtuales (VMware, VirtualBox, QEMU/KVM):** se exporta `GSK_RENDERER=gl` (evitando la emulación por CPU *Lavapipe*) y se genera `~/.cache/niri-vm-quirks.kdl` con `disable-cursor-plane` y `blur { off }` para mantener la fluidez.
  - **Pantalla de login (`greetd`):** el wrapper `/usr/libexec/noctalia-greeter-wrapper.sh` detecta `vmwgfx` (VMware) para activar renderizado por software (`pixman`) y evitar errores de `dma-buf`.
- **Discos Virtuales NVMe (VMware):** la regla `99-vmware-nvme.rules` detecta el controlador NVMe virtual de VMware (`0x15ad:0x07f0`) y ajusta `io_timeout=2000` (2 s) y `nr_requests=64` para evitar bloqueos de 30 s por pérdida de interrupciones MSI-X. Adicionalmente, en VMware se recomienda desactivar APST en los argumentos del kernel:
  ```bash
  sudo rpm-ostree kargs --append-if-missing=nvme_core.default_ps_max_latency_us=0
  ```
