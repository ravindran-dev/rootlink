#!/bin/bash
# Install Rootlink for the current user so launchers like wofi/rofi can find it.

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${HOME}/.local"

cmake --build "${ROOT_DIR}/build" --config Release
cmake --install "${ROOT_DIR}/build" --prefix "${PREFIX}"

DESKTOP_FILE="${PREFIX}/share/applications/rootlink.desktop"
if [ -f "${DESKTOP_FILE}" ]; then
    sed -i "s|^Exec=.*|Exec=${PREFIX}/bin/rootlink %U|" "${DESKTOP_FILE}"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${PREFIX}/share/applications" || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q "${PREFIX}/share/icons/hicolor" || true
fi

echo "Rootlink installed for this user."
echo "Launch it from wofi/rofi/app launcher as: Rootlink"
echo "Optional default file manager:"
echo "  xdg-mime default rootlink.desktop inode/directory"
