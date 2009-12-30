#!/bin/sh -efu

base="bat"

n=1

t(){
  local n=$1
  shift
  [ -s "$base$n.fig" ] || ln -s -- "$base.fig" "$base$n.fig"
  [ -s "$base$n.jpg" ] || ln -s -- "$base.jpg" "$base$n.jpg"
  rm -f -- "$base${n}_m.jpg"
  time ../ph_update_www "$@" "$base$n.jpg"
}

t 1
t 2 -H


