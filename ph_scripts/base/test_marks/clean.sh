#!/bin/sh -efu

base="bat"

n=1

for st in simple_gif aa_gif aa_gif_halo aa_gif_dark_halo; do
  for ext in _m.gif _m.png .htm; do
    rm -f -- "${base}_${st}$ext"
  done
done
