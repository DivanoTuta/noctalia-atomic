#!/usr/bin/sh
#
# Descripción : Sincroniza el avatar por defecto en AccountsService y la apariencia inicial
#               de Noctalia con noctalia-greeter en el primer inicio de sesión gráfico.
# Uso         : Ejecutado una sola vez por noctalia-first-login.service (systemd --user).
# Dependencias: sh (POSIX), busctl, id, mkdir, sleep, noctalia
#
set -eu

trap 'exit 130' INT
trap 'exit 143' TERM

if [ -z "${HOME:-}" ]; then
    exit 0
fi

default_avatar="/usr/share/noctalia-atomic/mountain.jpg"
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/noctalia-atomic"
marker_file="${state_dir}/first-login-done"

if [ -e "${marker_file}" ]; then
    exit 0
fi

all_ok=1

# 1. Registrar el avatar por defecto en AccountsService solo si el usuario aún no tiene uno válido
if [ -r "${default_avatar}" ] && command -v busctl >/dev/null 2>&1; then
    uid="$(id -u)"
    user_path="/org/freedesktop/Accounts/User${uid}"
    current_icon="$(busctl get-property org.freedesktop.Accounts "${user_path}" org.freedesktop.Accounts.User IconFile 2>/dev/null || true)"

    # AccountsService devuelve 's "/home/<user>/.face"' cuando aún no se ha fijado avatar
    case "${current_icon}" in
        '' | *'/.face"' | 's ""')
            if ! busctl call org.freedesktop.Accounts "${user_path}" org.freedesktop.Accounts.User SetIconFile s "${default_avatar}" >/dev/null 2>&1; then
                all_ok=0
            fi
            ;;
        *) ;;
    esac
fi

# 2. Sincronizar apariencia inicial con noctalia-greeter (solo usuarios en wheel para no pedir contraseña)
case " $(id -Gn) " in
    *" wheel "*)
        if command -v noctalia >/dev/null 2>&1; then
            # Dar margen a Noctalia para abrir su socket IPC y cargar fondo/paleta (máximo 30 s)
            attempt=0
            synced=0
            while [ "${attempt}" -lt 15 ]; do
                sleep 2
                if noctalia msg greeter-sync >/dev/null 2>&1; then
                    synced=1
                    break
                fi
                attempt=$((attempt + 1))
            done
            if [ "${synced}" -ne 1 ]; then
                all_ok=0
            fi
        fi
        ;;
    *) ;;
esac

# Guardar el marcador solo si todo terminó bien (si algo falló de forma transitoria, reintentará)
if [ "${all_ok}" -eq 1 ]; then
    mkdir -p -- "${state_dir}"
    : >"${marker_file}"
fi
