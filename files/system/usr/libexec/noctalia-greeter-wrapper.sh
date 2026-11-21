#!/usr/bin/sh
#
# Descripción : Lanza noctalia-greeter-session aplicando renderizado por software en VMware (vmwgfx).
# Uso         : noctalia-greeter-wrapper.sh [argumentos_adicionales...]
# Dependencias: sh (POSIX), noctalia-greeter-session
#
set -eu

# En máquinas virtuales con GPU virtual VMware SVGA3D (vmwgfx), wlroots falla
# al importar dma-bufs por hardware (protocol error 7) y el plano de cursor DRM falla.
# En hardware real (AMD/Intel/NVIDIA) se ejecuta con aceleración GPU nativa.
if [ -d /sys/module/vmwgfx ]; then
    export WLR_RENDERER=pixman
    export WLR_NO_HARDWARE_CURSORS=1
    export LIBGL_ALWAYS_SOFTWARE=1
fi

exec /usr/bin/noctalia-greeter-session --session Niri "$@"
