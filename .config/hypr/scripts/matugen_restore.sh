#!/usr/bin/env bash
CACHE_IMG="$HOME/.cache/wallpaper_picker/current_wallpaper.png"

# Espera un poco a que el entorno gráfico esté listo antes de tocar nada
sleep 1

if [ -f "$CACHE_IMG" ]; then
    SAT=$(magick "$CACHE_IMG" -resize 1x1^ -format "%[fx:saturation]" info:- 2>/dev/null)
    if awk "BEGIN{exit !($SAT < 0.12)}"; then
        TYPE_FLAG="-t scheme-monochrome"
    else
        TYPE_FLAG=""
    fi
    matugen image "$CACHE_IMG" $TYPE_FLAG || true
fi
