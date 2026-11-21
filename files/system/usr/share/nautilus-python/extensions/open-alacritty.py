"""Extensión de Nautilus para abrir carpetas locales en Alacritty."""

import logging
import shutil
from pathlib import Path
from typing import TYPE_CHECKING, Final, Protocol, cast

import gi

if TYPE_CHECKING:
    from collections.abc import Sequence

gi.require_version("Nautilus", "4.0")

# gi.require_version debe ejecutarse antes de importar gi.repository
from gi.repository import GLib, GObject, Nautilus

logger = logging.getLogger(__name__)

_DEFAULT_TERMINAL_PATH: Final[str] = "/usr/bin/alacritty"


class _FileLocation(Protocol):
    """Subconjunto mínimo de ``Gio.File`` usado para resolver rutas locales."""

    def get_path(self) -> str | None:
        """Devuelve la ruta local del archivo o ``None`` si no es local."""
        ...


class _NautilusFileInfo(Protocol):
    """Subconjunto mínimo de ``Nautilus.FileInfo`` usado por la extensión."""

    def is_directory(self) -> bool:
        """Indica si el elemento representa un directorio."""
        ...

    def get_uri_scheme(self) -> str:
        """Devuelve el esquema URI del elemento (por ejemplo, ``file``)."""
        ...

    def get_location(self) -> _FileLocation | None:
        """Devuelve el objeto de ubicación asociado al elemento."""
        ...


class OpenAlacrittyExtension(
    GObject.GObject,  # type: ignore[misc]  # PyGObject no provee stubs tipados en el host
    Nautilus.MenuProvider,  # type: ignore[misc]  # PyGObject no provee stubs tipados en el host
):
    """Añade la acción «Abrir en Alacritty» al menú contextual de Nautilus."""

    def _resolve_local_directory(
        self,
        file_info: _NautilusFileInfo,
        *,
        require_directory: bool = True,
    ) -> Path | None:
        """Resuelve una ruta local válida a partir de un elemento de Nautilus."""
        if require_directory and not file_info.is_directory():
            return None
        if file_info.get_uri_scheme() != "file":
            return None
        location = file_info.get_location()
        raw_path = location.get_path() if location is not None else None
        if not raw_path:
            return None
        directory = Path(raw_path)
        return directory if directory.is_dir() else None

    def _open_terminal(self, _menu: object, directory: Path) -> None:
        """Lanza Alacritty desvinculado de Nautilus en la carpeta indicada."""
        if not directory.is_dir():
            logger.warning("La carpeta ya no existe: %s", directory)
            return

        terminal_bin = shutil.which("alacritty") or _DEFAULT_TERMINAL_PATH
        try:
            # GLib.spawn_async recoge el hijo sin dejar procesos zombi en Nautilus
            GLib.spawn_async([terminal_bin, "--working-directory", str(directory)])
        except GLib.Error:
            logger.exception("No se pudo abrir Alacritty en %s", directory)

    def _create_item(self, name: str, directory: Path) -> object:
        """Construye un elemento de menú contextual para abrir Alacritty."""
        item = Nautilus.MenuItem(
            name=name,
            label="Abrir en Alacritty",
            tip="Abrir una terminal Alacritty en esta carpeta",
            icon="utilities-terminal-symbolic",
        )
        item.connect("activate", self._open_terminal, directory)
        return item

    def get_file_items(self, *args: object) -> list[object]:
        """Devuelve acciones contextuales al seleccionar una carpeta en Nautilus.

        Se acepta ``*args`` para mantener compatibilidad entre ``nautilus-python`` 4.x
        (``(files,)``) y 3.x (``(window, files)``).

        Args:
            *args: Argumentos pasados por Nautilus (el último es la lista de archivos).

        Returns:
            Lista con el elemento de menú si hay una única carpeta local seleccionada,
            o lista vacía en caso contrario.
        """
        if not args or args[-1] is None:
            return []
        files = cast("Sequence[_NautilusFileInfo]", args[-1])
        if len(files) != 1:
            return []
        directory = self._resolve_local_directory(files[0], require_directory=True)
        if directory is None:
            return []
        return [self._create_item("NoctaliaNautilus::open_alacritty_dir", directory)]

    def get_background_items(self, *args: object) -> list[object]:
        """Devuelve acciones contextuales al hacer clic en el fondo de una carpeta.

        Se acepta ``*args`` para mantener compatibilidad entre ``nautilus-python`` 4.x
        (``(folder,)``) y 3.x (``(window, folder)``).

        Args:
            *args: Argumentos pasados por Nautilus; el último es la carpeta actual.

        Returns:
            Lista con el elemento de menú si la carpeta actual es local,
            o lista vacía en caso contrario.
        """
        if not args or args[-1] is None:
            return []
        folder = cast("_NautilusFileInfo", args[-1])
        directory = self._resolve_local_directory(folder, require_directory=False)
        if directory is None:
            return []
        return [self._create_item("NoctaliaNautilus::open_alacritty_bg", directory)]
