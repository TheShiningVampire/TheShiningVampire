#!/usr/bin/env bash
# Install whatever the paper-video skill is missing (Debian/Ubuntu). Safe to re-run:
# a machine that already passes check_env.sh is left untouched, and only missing pieces
# are installed otherwise. Respects PAPER_VIDEO_PY and an existing conda install.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# 0. Already set up (default env or PAPER_VIDEO_PY): change nothing.
if out="$(bash "$HERE/check_env.sh" 2>&1)"; then
  echo "paper-video toolchain already installed; nothing to do."
  echo "$out" | tail -1
  exit 0
fi

# 1. System tools: install only the apt packages whose tools are missing.
pkgs=()
command -v ffmpeg   >/dev/null && command -v ffprobe >/dev/null || pkgs+=(ffmpeg)
command -v pdftoppm >/dev/null || pkgs+=(poppler-utils)
command -v latex    >/dev/null || pkgs+=(texlive-latex-base texlive-fonts-recommended cm-super)
command -v latex >/dev/null && kpsewhich standalone.cls >/dev/null 2>&1 \
  && kpsewhich preview.sty >/dev/null 2>&1 || pkgs+=(texlive-latex-extra texlive-science)
command -v dvisvgm  >/dev/null || pkgs+=(dvisvgm)
command -v espeak-ng >/dev/null || pkgs+=(espeak-ng)
command -v curl     >/dev/null || pkgs+=(curl)
if [ ${#pkgs[@]} -gt 0 ]; then
  if ! command -v apt-get >/dev/null; then
    echo "Install these yourself (no apt-get): ${pkgs[*]}" >&2
  else
    SUDO=""
    if [ "$(id -u)" != 0 ]; then
      # Without a terminal (e.g. run by Claude) sudo can't ask for a password: don't hang.
      if [ -t 0 ]; then SUDO="sudo"; elif sudo -n true 2>/dev/null; then SUDO="sudo -n"; else
        echo "Needs sudo; run this yourself: sudo apt-get install -y ${pkgs[*]}" >&2; SUDO=skip; fi
    fi
    if [ "$SUDO" != skip ]; then
      $SUDO apt-get update -qq
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends "${pkgs[@]}" libsndfile1
    fi
  fi
fi

# 2. Python: PAPER_VIDEO_PY wins if set; otherwise reuse any existing conda.
if [ -n "${PAPER_VIDEO_PY:-}" ]; then
  PY="$PAPER_VIDEO_PY"
  "$PY" -c "import manim" 2>/dev/null || "$PY" -m pip install -q manim
else
  CONDA=""
  for c in "${CONDA_EXE:-}" "$(command -v conda 2>/dev/null || true)" \
           "$HOME"/{miniconda3,miniforge3,mambaforge,anaconda3}/bin/conda; do
    [ -n "$c" ] && [ -x "$c" ] && { CONDA="$c"; break; }
  done
  if [ -z "$CONDA" ]; then
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/mc.sh" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
      || curl -fsSL -o "$tmp/mc.sh" https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    bash "$tmp/mc.sh" -b -p "$HOME/miniconda3"
    rm -rf "$tmp"
    CONDA="$HOME/miniconda3/bin/conda"
  fi
  BASE="$("$CONDA" info --base)"
  PY="$BASE/envs/paper-video/bin/python"
  [ -x "$PY" ] || "$CONDA" create -y -q -n paper-video -c conda-forge --override-channels python=3.11 manim
  "$PY" -c "import manim" 2>/dev/null || "$CONDA" install -y -q -n paper-video -c conda-forge --override-channels manim
fi

# 3. Kokoro TTS, only if missing (never upgrades what's there).
"$PY" -c "import kokoro, soundfile" 2>/dev/null || "$PY" -m pip install -q kokoro soundfile

PAPER_VIDEO_PY="$PY" bash "$HERE/check_env.sh"
[ "$PY" = "$HOME/miniconda3/envs/paper-video/bin/python" ] || \
  echo "Note: the env is at $PY; export PAPER_VIDEO_PY=$PY so the skill finds it."
