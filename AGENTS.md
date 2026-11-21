# AGENTS.md

## What this repo is

BlueBuild recipe repo that builds a Fedora Atomic / uBlue bootc image (`ghcr.io/ublue-os/base-main`), not an application codebase. There is no app source, test suite, or package manifest. The build inputs are `recipes/recipe.yml` and the `files/` tree.

## Commands

- Fast recipe check without building: `bluebuild validate recipes/recipe.yml`.
- Inspect the generated Containerfile (stdout): `bluebuild generate recipes/recipe.yml`; add `-d` to print the fully resolved recipe instead.
- Build locally (from repo root): `bluebuild build ./recipes/recipe.yml`
  - Requires BlueBuild CLI + Podman and ~20-25 GB free disk / 4-6 GB RAM.
  - Output image: `localhost/noctalia-atomic:latest`.
- Apply the locally built image: `sudo bootc switch --transport containers-storage localhost/noctalia-atomic:latest` then `systemctl reboot`.
- Validation for changed scripts:
  - Early-boot/system scripts (`files/system/usr/libexec/noctalia-greeter-wrapper.sh`, `files/system/usr/lib/systemd/user-environment-generators/10-noctalia-graphics.sh`) are POSIX `/usr/bin/sh`: run `shfmt -d -i 4 -ci`, `sh -n`, and `shellcheck --shell=sh`.
  - If adding interactive CLI scripts in the future, use Bash 5+ (`#!/usr/bin/env bash`) and validate with `shfmt -d -i 4 -ci`, `bash -n`, and `shellcheck --shell=bash`.
  - Python extension (`files/system/usr/share/nautilus-python/extensions/open-alacritty.py`): run `ruff format --check`, `ruff check`, and `mypy --strict --ignore-missing-imports`.
- CI is authoritative: `.github/workflows/build.yml` runs a `validate` job (shfmt, shellcheck, ruff, `bluebuild validate`) before building on pushes/PRs to `main` touching `recipes/**`, `files/**`, `modules/**`, `cosign.pub` or the workflow, daily at 06:00 UTC, and manually. It needs the `SIGNING_SECRET` repository secret.

## Layout and editing rules

- `files/system/` is overlaid verbatim onto `/` by the `files` module (which runs after `dnf` in `recipes/recipe.yml`). To change `/etc/skel/foo`, edit `files/system/etc/skel/foo` (no extra `system/` path segment).
- `files/dnf/*.repo` are repo definitions referenced by `recipe.yml` (`dnf.repos.files`), not files installed into the image. Repo packages are installed by the `dnf` module.
- `recipes/recipe.yml` is the single source of truth for dnf packages, Flatpaks, fonts, systemd enable/mask state, and signing. Prefer adding packages there over ad-hoc install scripts.
- `files/system/usr/share/noctalia-atomic/greeter.toml` is the source of truth. `files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf` copies it with `C+` (overwriting on boot) to `/var/lib/noctalia-greeter/greeter.toml`; edit the source, not the generated copy. This declarative file overrides `sync.toml`.
- Vendor drop-ins and system wrappers live under `/usr`: `files/system/usr/lib/systemd/system/greetd.service.d/override.conf` and `files/system/usr/libexec/noctalia-greeter-wrapper.sh`.
- `~/.cache/niri-vm-quirks.kdl` is generated atomically by `10-noctalia-graphics.sh` and included optionally by `niri/config.kdl`. Do not hardcode VM-only quirks into `config.kdl`; greeter VM handling lives in `noctalia-greeter-wrapper.sh` (`vmwgfx` -> software rendering).
- Dotfiles live under `/etc/skel` and only affect newly created users; changes do not migrate existing home directories. Mention this when a change is meant for current users.
- System updates delegate directly to Universal Blue's native `ujust update` (`rpm-ostree update`, `flatpak update`, `distrobox upgrade`) via `files/system/usr/share/applications/system-update.desktop` (`alacritty --hold --class noctalia-system-update ... -e ujust update`) and the Fish `update` alias. Automatic background staging is handled by `rpm-ostreed-automatic.timer` (toggleable with `ujust toggle-updates`).
- `nethogs` capabilities (`recipe.yml`) and RAPL `energy_uj` permissions (`99-powercap.rules`) are restricted to the `wheel` group so Mission Center works for admin users while limiting local exposure.
- The CI path filter mentions `modules/**`, but no `modules/` directory exists. Create it only when adding custom BlueBuild modules.
- `Containerfile` is generated locally and gitignored; do not edit or commit it.

## Conventions

- Docs, code comments, UI strings, and commit messages are in Spanish; keep that style. Commits use `feat:` / `fix:` prefixes.
- Early-boot/system scripts use `#!/usr/bin/sh` (POSIX, no Bashisms); interactive CLI scripts (if added) use `#!/usr/bin/env bash` (Bash 5+ strict mode).
- Never commit `cosign.key` or any `*.key` (gitignored). The public key is `cosign.pub`; CI signing uses `SIGNING_SECRET`.
- Niri comes from the `yalter/niri` COPR; `noctalia-greeter` comes from the `lionheartp/Hyprland` repo, which is restricted via `includepkgs=noctalia-greeter*`.
