#!/usr/bin/env bash
# Applies a manual color to matugen, persisting it as an override so it
# survives reboots until the user either picks another color or changes
# the wallpaper (which clears the override).
#
# Usage: apply_color.sh "#RRGGBB" [scheme-type]
#   scheme-type defaults to auto-detected (monochrome for grayscale, tonal-spot otherwise)

set -euo pipefail

HEX="${1:?Usage: apply_color.sh <#hex> [scheme-type]}"
SCHEME="${2:-}"

OVERRIDE_FILE="$HOME/.config/hypr/color_override.json"
RELOAD_SCRIPT="$HOME/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"

# Auto-detect monochrome (grayscale) colors if no scheme was explicitly requested
if [ -z "$SCHEME" ]; then
    R=$((16#${HEX:1:2}))
    G=$((16#${HEX:3:2}))
    B=$((16#${HEX:5:2}))
    MAXV=$(( R > G ? (R > B ? R : B) : (G > B ? G : B) ))
    MINV=$(( R < G ? (R < B ? R : B) : (G < B ? G : B) ))
    DIFF=$(( MAXV - MINV ))
    if [ "$DIFF" -lt 12 ]; then
        SCHEME="scheme-monochrome"
    else
        SCHEME="scheme-tonal-spot"
    fi
fi

matugen color hex "$HEX" -t "$SCHEME"

# Persist the override so init.sh knows to re-apply THIS color (not the
# wallpaper's) on the next login/reboot.
cat > "$OVERRIDE_FILE" << EOF
{
  "active": true,
  "hex": "$HEX",
  "scheme": "$SCHEME"
}
EOF

if [ -f "$RELOAD_SCRIPT" ]; then
    chmod +x "$RELOAD_SCRIPT"
    bash "$RELOAD_SCRIPT"
fi
