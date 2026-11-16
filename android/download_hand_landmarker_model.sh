#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSET_DIR="$ROOT/android/plugins/hands_tracking/src/main/assets"
MODEL="$ASSET_DIR/hand_landmarker.task"
mkdir -p "$ASSET_DIR"
if [[ -f "$MODEL" ]]; then
  echo "Model already exists: $MODEL"
  exit 0
fi
curl --fail --location --retry 3 \
  'https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task' \
  --output "$MODEL"
echo "Downloaded official MediaPipe Hand Landmarker task model: $MODEL"
