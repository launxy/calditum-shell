#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "wallpaper_picker"

FLAG="$QS_STATE_WALLPAPER_PICKER/wallpaper_initialized"
CACHE_IMG="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper.png"
COLOR_OVERRIDE="$HOME/.config/hypr/color_override.json"

RELOAD_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/quickshell/wallpaper/matugen_reload.sh"

# If a manual color override is active, re-apply THAT instead of the
# wallpaper's colors — it stays in effect until the user picks another
# color, or explicitly changes the wallpaper (which clears this file).
if [ -f "$COLOR_OVERRIDE" ] && command -v jq >/dev/null; then
    IS_ACTIVE=$(jq -r '.active // false' "$COLOR_OVERRIDE")
    if [ "$IS_ACTIVE" = "true" ]; then
        HEX=$(jq -r '.hex' "$COLOR_OVERRIDE")
        SCHEME=$(jq -r '.scheme' "$COLOR_OVERRIDE")
        matugen color hex "$HEX" -t "$SCHEME"

        if [ -f "$RELOAD_SCRIPT_PATH" ]; then
            chmod +x "$RELOAD_SCRIPT_PATH"
            bash "$RELOAD_SCRIPT_PATH"
        fi

        mkdir -p "$(dirname "$FLAG")"
        touch "$FLAG"
        exit 0
    fi
fi

# If the flag exists, just run matugen and the reload script, then exit
if [ -f "$FLAG" ]; then
    # Use the cached wallpaper image for matugen
    if [ -f "$CACHE_IMG" ]; then
        SAT=$(magick "$CACHE_IMG" -resize 1x1^ -format "%[fx:saturation]" info:- 2>/dev/null)
        if awk "BEGIN{exit !($SAT < 0.12)}"; then
            TYPE_FLAG="-t scheme-monochrome"
        else
            TYPE_FLAG=""
        fi
        matugen image "$CACHE_IMG" --source-color-index 0 $TYPE_FLAG
    fi
    
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
    
    exit 0
fi

# If no wallpaper dir is set, default to a common one to prevent find from failing
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

sleep 0.5

# Find a random file
file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    # Copy to our persistent cache location instead of /tmp
    cp "$file" "$CACHE_IMG"
    
    awww img "$file" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    
    SAT=$(magick "$file" -resize 1x1^ -format "%[fx:saturation]" info:- 2>/dev/null)
    if awk "BEGIN{exit !($SAT < 0.12)}"; then
        TYPE_FLAG="-t scheme-monochrome"
    else
        TYPE_FLAG=""
    fi
    matugen image "$file" --source-color-index 0 $TYPE_FLAG
    
    # Execute reload script if it exists
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
