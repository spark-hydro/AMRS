#!/bin/sh
# Starts AMRS. Normal (fast) build by default; the debug build with -e DEBUG=1.
case "${DEBUG:-0}" in
  0|false|FALSE|False|no|NO|"")
    exec amrs-release "$@" ;;
  *)
    echo "[amrs docker] DEBUG build: checks array bounds, about 3x slower." >&2
    exec amrs-debug "$@" ;;
esac
