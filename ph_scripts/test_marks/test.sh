#!/bin/sh -efu

base="bat"

n=1

for st in simple_gif aa_gif aa_gif_halo aa_gif_dark_halo; do
  ../ph_update_www -t "style: $st" -m "$st" $base.jpg
  for ext in _m.gif _m.png .htm; do
    [ -f ${base}$ext ] &&
      mv -f -- ${base}$ext ${base}_${st}$ext ||:
  done
  sed -i "s|src=\"${base}_m|src=\"${base}_${st}_m|" ${base}_${st}.htm
  rm -f -- _$base.jpg
done
