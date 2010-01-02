#!/bin/sh -efu

base="bat"

n=1

t(){
  local n=$1
  shift
  [ -s "$base$n.fig" ] || ln -s -- "$base.fig" "$base$n.fig"
  [ -s "$base$n.jpg" ] || ln -s -- "$base.jpg" "$base$n.jpg"
  rm -f -- "$base${n}_m.gif"
  echo ">>> ph_update_www $* $base$n.jpg"
  time ../ph_update_www "$@" "$base$n.jpg"
}

t 1 -m simple_gif
t 2 -m aa_gif
t 3 -m aa_gif_halo
t 4 -m aa_gif_dark_halo


