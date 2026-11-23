# AGENTS.md

## What this repo is

BlueBuild recipe repo that builds a Fedora Atomic / uBlue bootc image (`ghcr.io/ublue-os/base-main`), not an application codebase. There is no app source, test suite, or package manifest. The build inputs are `recipes/recipe.yml` and the `files/` tree.

## Security & Secrets (MANDATORY)

- **STRICT PROHIBITION — Private keys (`cosign.key`, `*.key`):** Agents MUST NEVER read, open, inspect, print, search inside, copy, encode, stage, or commit `cosign.key` or any `*.key` file, under any circumstances.
  - This prohibition applies to **all** tools and commands without exception: file-reading tools, search/grep tools, shell commands (`cat`, `head`, `tail`, `less`, `grep`, `rg`, `sed`, `awk`, `strings`, `base64`, `xxd`, `python`, etc.), and git commands (`git add`, `git diff`, `git show`).
  - Checking mere file presence or permissions via metadata-only listing (e.g., `ls -la cosign*`) without reading file contents is allowed only when strictly necessary.
  - If a task requires using, rotating, or configuring `cosign.key` (for example, setting the `SIGNING_SECRET` secret in GitHub), do **not** access the file; instruct the user to perform that step directly.
- Only `cosign.pub` (the public verification key) may be read and committed to Git. CI image signing uses the `SIGNING_SECRET` GitHub repository secret.

## Commands

- Fast recipe check without building: `bluebuild validate recipes/recipe.yml`.
- Inspect the generated Containerfile (stdout): `bluebuild generate recipes/recipe.yml`; add `-d` to print the fully resolved recipe instead.
- Build locally (from repo root): `bluebuild build ./recipes/recipe.yml`
  - Requires BlueBuild CLI + Podman and ~20-25 GB free disk / 4-6 GB RAM.
  - Output image: `localhost/noctalia-atomic:latest`.
- Apply the locally built image: `sudo bootc switch --transport containers-storage localhost/noctalia-atomic:latest` then `systemctl reboot`.
- Validation for changed scripts:
  - `.editorconfig` defines shell formatting (`indent_style = space`, `indent_size = 4`, `switch_case_indent = true`); run `shfmt -d` without `-i`/`-ci` flags so it honors `.editorconfig`.
  - Early-boot/system scripts (`files/system/usr/libexec/noctalia-greeter-wrapper.sh`, `files/system/usr/lib/systemd/user-environment-generators/10-noctalia-graphics.sh`) are POSIX `/usr/bin/sh`: run `shfmt -d`, `sh -n`, and `shellcheck --shell=sh --external-sources`.
  - If adding interactive CLI scripts in the future, use Bash 5+ (`#!/usr/bin/env bash`) and validate with `shfmt -d`, `bash -n`, and `shellcheck --shell=bash --external-sources`.
  - Python extension (`files/system/usr/share/nautilus-python/extensions/open-alacritty.py`): run `ruff format --check`, `ruff check`, and `mypy --strict --ignore-missing-imports`.
- CI is authoritative: `.github/workflows/build.yml` runs a `validate` job (`shfmt`, `shellcheck` on `files/` scripts and `recipe.yml` script snippets, `desktop-file-validate`, `ruff`, `tomllib` TOML check, `mypy`, `bluebuild validate`) before building on pushes/PRs to `main` touching `recipes/**`, `files/**`, `modules/**`, `cosign.pub`, `.editorconfig` or the workflow, daily at 06:00 UTC, and manually. It needs the `SIGNING_SECRET` repository secret.

## Layout and editing rules

- `files/system/` is overlaid verbatim onto `/` by the `files` module (which runs after `dnf` in `recipes/recipe.yml`). To change `/etc/skel/foo`, edit `files/system/etc/skel/foo` (no extra `system/` path segment).
- `files/dnf/*.repo` are repo definitions referenced by `recipe.yml` (`dnf.repos.files`), not files installed into the image. Repo packages are installed by the `dnf` module.
- `recipes/recipe.yml` is the single source of truth for dnf packages, Flatpaks, fonts, systemd enable/mask state, and signing. Prefer adding packages there over ad-hoc install scripts.
- `files/system/usr/share/noctalia-atomic/greeter.toml` is the source of truth. `files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf` copies it with `C+` (overwriting on boot) to `/var/lib/noctalia-greeter/greeter.toml`; edit the source, not the generated copy. This declarative file overrides `sync.toml`.
- Vendor drop-ins and system wrappers live under `/usr`: `files/system/usr/lib/systemd/system/greetd.service.d/override.conf` and `files/system/usr/libexec/noctalia-greeter-wrapper.sh`.
- `~/.cache/niri-vm-quirks.kdl` is generated atomically by `10-noctalia-graphics.sh` and included optionally by `niri/config.kdl`. Do not hardcode VM-only quirks into `config.kdl`; greeter VM handling lives in `noctalia-greeter-wrapper.sh` (`vmwgfx` -> software rendering + `WLR_DRM_NO_ATOMIC=1`).
- In BlueBuild's `dnf` module, `remove` runs **before** `install`. Use `install.exclude` (not `remove.packages`) to block unwanted weak dependencies (`fuzzel`, `waybar`, `swaylock`, `gnome-keyring`, `gnome-keyring-pam` from `niri`), and keep `mate-polkit` installed to satisfy `gparted`'s `PolicyKit-authentication-agent` without pulling GNOME Shell/Mutter/GDM (`polkit-gnome` is retired in Fedora 45; `mate-polkit` uses `OnlyShowIn=MATE;` so it never autostarts in Niri).
- Secret Service uses `oo7` (`oo7-daemon`, `oo7-portal`, `pam_oo7`) exclusively: `oo7-daemon.service` is enabled in `systemd.user.enabled`, D-Bus activation is provided by `files/system/usr/share/dbus-1/services/org.freedesktop.secrets.service`, Flatpak Secret portal routes to `oo7-portal` via `files/system/usr/share/xdg-desktop-portal/niri-portals.conf`, and `recipe.yml` ensures `-password optional pam_oo7.so use_authtok` in `/etc/pam.d/passwd` and `/usr/lib/pam.d/greetd`.
- `app-blueman@autostart.service` is masked in `systemd.user.masked` so `blueman-applet` does not duplicate Noctalia's native Bluetooth widget at login; `blueman-manager` and `blueman-sendto` still activate it on demand via D-Bus.
- Dotfiles live under `/etc/skel` and only affect newly created users; changes do not migrate existing home directories. Mention this when a change is meant for current users.
- Default icon and GTK themes (`Papirus-Dark` from `papirus-icon-theme` and `adw-gtk3-dark` / `prefer-dark` from `adw-gtk3-theme`) are configured system-wide via `files/system/usr/share/glib-2.0/schemas/99-noctalia-atomic.gschema.override` (compiled in `recipe.yml` with `glib-compile-schemas`) plus `/etc/skel/.config/gtk-{3,4}.0/settings.ini`.
- Default user avatar (`files/system/usr/share/noctalia-atomic/mountain.jpg`) is referenced via `avatar_path` in `/etc/skel/.config/noctalia/config.toml` and synced to `noctalia-greeter` through `accountsservice` (`accounts-daemon.service` enabled in `systemd.system.enabled`).
- System updates delegate directly to Universal Blue's native `ujust update` (`rpm-ostree update`, `flatpak update`, `distrobox upgrade`) via `files/system/usr/share/applications/system-update.desktop` (`alacritty --class noctalia-system-update ... -e /usr/bin/sh -c ...` with an end-of-run `Enter`-to-close prompt) and the Fish `update` alias. Automatic background staging is handled by `rpm-ostreed-automatic.timer` (toggleable with `ujust toggle-updates`).
- `nethogs` capabilities (`recipe.yml`), RAPL `energy_uj` permissions (`99-powercap.rules`), and passwordless `noctalia-greeter` appearance sync (`files/system/usr/share/polkit-1/rules.d/49-noctalia-greeter-sync.rules`) are restricted to the `wheel` group so admin workflows work smoothly while limiting local exposure.
- The CI path filter mentions `modules/**`, but no `modules/` directory exists. Create it only when adding custom BlueBuild modules.
- `Containerfile` is generated locally and gitignored; do not edit or commit it.

## Conventions

- Docs, code comments, UI strings, and commit messages are in Spanish; keep that style. Commits use `feat:` / `fix:` prefixes.
- Early-boot/system scripts use `#!/usr/bin/sh` (POSIX, no Bashisms); interactive CLI scripts (if added) use `#!/usr/bin/env bash` (Bash 5+ strict mode).
- Niri comes from the `yalter/niri` COPR; `noctalia-greeter` comes from the `lionheartp/Hyprland` repo (`includepkgs=noctalia-greeter*`); VS Code comes from `vscode.repo` (`includepkgs=code`).
