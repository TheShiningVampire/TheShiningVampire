#!/usr/bin/env bash
# Install everything the paper-video skill needs (Debian/Ubuntu). Safe to re-run.
# System packages need root or sudo; the Python env goes in ~/miniconda3/envs/paper-video.
set -euo pipefail

SUDO=""; [ "$(id -u)" = 0 ] || SUDO="sudo"
CONDA_DIR="${CONDA_DIR:-$HOME/miniconda3}"
ENV="$CONDA_DIR/envs/paper-video"

# 1. System tools: ffmpeg, pdftoppm, LaTeX (+ standalone/preview), dvisvgm, espeak-ng for Kokoro
if command -v apt-get >/dev/null; then
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends \
    ffmpeg poppler-utils texlive-latex-base texlive-latex-extra texlive-fonts-recommended \
    texlive-science cm-super dvisvgm espeak-ng libsndfile1 curl
else
  echo "No apt-get: install ffmpeg, poppler, a TeX Live with dvisvgm, and espeak-ng yourself." >&2
fi

# 2. Conda (Miniconda; falls back to Miniforge)
if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/mc.sh" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    || curl -fsSL -o "$tmp/mc.sh" https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
  bash "$tmp/mc.sh" -b -p "$CONDA_DIR"
  rm -rf "$tmp"
fi

# 3. Python env with Manim, plus Kokoro TTS
[ -x "$ENV/bin/python" ] || "$CONDA_DIR/bin/conda" create -y -q -n paper-video -c conda-forge --override-channels python=3.11 manim
"$ENV/bin/pip" install -q kokoro soundfile

bash "$(dirname "$0")/check_env.sh"
