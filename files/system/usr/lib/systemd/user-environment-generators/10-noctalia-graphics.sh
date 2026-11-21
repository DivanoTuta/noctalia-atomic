#!/usr/bin/sh
#
# Descripción : Generador de entorno systemd para ajustar renderizado GTK4 y quirks DRM de Niri en VMs.
# Uso         : Ejecutado automáticamente por systemd --user (user-environment-generators).
# Dependencias: sh (POSIX), systemd-detect-virt, mkdir, mktemp, mv, rm
#
set -eu

# Si el sistema corre dentro de una máquina virtual (sin Vulkan por hardware en la GPU virtual),
# forzamos GSK_RENDERER=gl para evitar Lavapipe (emulación por CPU) y desactivamos tanto el plano
# de cursor DRM como el blur en Niri para mantener fluidez. En hardware real usamos Vulkan nativo,
# cursor DRM por hardware y blur nativo.
is_vm=0
if /usr/bin/systemd-detect-virt --quiet --vm || [ -d /sys/module/vmwgfx ]; then
    is_vm=1
    printf 'GSK_RENDERER=gl\n'
fi

# Niri incluye de forma opcional ~/.cache/niri-vm-quirks.kdl; si HOME no está definido, omitimos la escritura.
if [ -z "${HOME:-}" ]; then
    exit 0
fi

cache_dir="${HOME}/.cache"
quirks_file="${cache_dir}/niri-vm-quirks.kdl"
mkdir -p -- "${cache_dir}" 2>/dev/null || exit 0

tmp_file=""
cleanup() {
    if [ -n "${tmp_file}" ] && [ -e "${tmp_file}" ]; then
        rm -f -- "${tmp_file}" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Escritura atómica mediante archivo temporal para evitar lecturas parciales si Niri recarga en vivo.
tmp_file="$(mktemp "${cache_dir}/.niri-vm-quirks.XXXXXX" 2>/dev/null)" || exit 0

if [ "${is_vm}" -eq 1 ]; then
    write_ok=1
    printf 'debug {\n    disable-cursor-plane\n}\n\nblur {\n    off\n}\n' >"${tmp_file}" 2>/dev/null || write_ok=0
else
    write_ok=1
    printf '// Hardware real: cursor DRM por hardware y blur nativo activos\n' >"${tmp_file}" 2>/dev/null || write_ok=0
fi

if [ "${write_ok}" -eq 1 ] && mv -f -- "${tmp_file}" "${quirks_file}" 2>/dev/null; then
    tmp_file=""
fi
