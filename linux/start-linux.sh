#!/usr/bin/env bash
# ===================================================
#     PENDRIVE_X AI - Launcher (Linux) [FIXED]
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DGRAY='\033[0;90m'
NC='\033[0m'

USB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── State for cleanup ─────────────────────────────────────────
OLLAMA_PID=""
ANYTHINGLLM_PID=""
APPIMAGE_EXTRACTED=0

cleanup() {
    echo ""
    echo "Shutting down AI Engine..."
    [[ -n "$ANYTHINGLLM_PID" ]] && kill "$ANYTHINGLLM_PID" 2>/dev/null || true
    [[ -n "$OLLAMA_PID" ]] && kill "$OLLAMA_PID" 2>/dev/null || true
    # Give processes a moment to die gracefully
    [[ -n "$ANYTHINGLLM_PID" ]] && wait "$ANYTHINGLLM_PID" 2>/dev/null || true
    [[ -n "$OLLAMA_PID" ]] && wait "$OLLAMA_PID" 2>/dev/null || true
    # If AppImage used extract-and-run, clean up the mount temp dir
    if (( APPIMAGE_EXTRACTED )); then
        for tmp in /tmp/.mount_Anything*; do
            [[ -d "$tmp" ]] && rm -rf "$tmp" 2>/dev/null || true
        done
    fi
    echo -e "${GREEN}AI Engine shut down. You may safely eject the USB.${NC}"
    sleep 1
}
trap cleanup EXIT INT TERM HUP

# ── Header ────────────────────────────────────────────────────
echo -e "${CYAN}==================================================="
echo -e "     Launching PENDRIVE_X AI Engine from USB..."
echo -e "===================================================${NC}"

# ── Path virtualization (everything stays on USB) ─────────────
export OLLAMA_MODELS="$USB_DIR/ollama/data"
export STORAGE_DIR="$USB_DIR/anythingllm_data"

export XDG_CONFIG_HOME="$STORAGE_DIR/config"
export XDG_DATA_HOME="$STORAGE_DIR/data"
export XDG_CACHE_HOME="$STORAGE_DIR/cache"

mkdir -p \
    "$STORAGE_DIR" \
    "$STORAGE_DIR/storage" \
    "$XDG_CONFIG_HOME" \
    "$XDG_DATA_HOME" \
    "$XDG_CACHE_HOME"

OLLAMA_BIN="$USB_DIR/ollama/ollama"
APPIMAGE="$USB_DIR/anythingllm/AnythingLLM.AppImage"

# ── Find a free port for Ollama ─────────────────────────────────
find_free_port() {
    local port
    for port in $(seq 11434 11534); do
        (exec 2>/dev/null; echo >/dev/tcp/127.0.0.1/$port) || { echo "$port"; return 0; }
    done
    echo "11434"  # fallback: will fail later if truly occupied
}
OLLAMA_PORT=$(find_free_port)
OLLAMA_HOST="127.0.0.1:${OLLAMA_PORT}"
export OLLAMA_HOST

echo -e "${DGRAY}  Using Ollama port: ${OLLAMA_PORT}${NC}"

# ── Read default model ────────────────────────────────────────
DEFAULT_MODEL="nemomix-local"
MODELS_FILE="$USB_DIR/models/installed-models.txt"
if [[ -f "$MODELS_FILE" ]]; then
    FIRST_LINE=$(head -1 "$MODELS_FILE")
    DEFAULT_MODEL="${FIRST_LINE%%|*}"
fi

# ── Configure .env ──────────────────────────────────────────────
ENV_FILE="$STORAGE_DIR/storage/.env"
needs_fix=false

[[ ! -f "$ENV_FILE" ]] && needs_fix=true
if [[ -f "$ENV_FILE" ]]; then
    grep -q "LLM_PROVIDER=ollama" "$ENV_FILE" || needs_fix=true
    grep -q "LLM_PROVIDER=anythingllm_ollama" "$ENV_FILE" && needs_fix=true
    grep -q "OLLAMA_BASE_PATH=http://${OLLAMA_HOST}" "$ENV_FILE" || needs_fix=true
fi

if $needs_fix; then
    echo "Configuring AnythingLLM to use external Ollama engine..."
    cat > "$ENV_FILE" <<EOF
LLM_PROVIDER=ollama
OLLAMA_BASE_PATH=http://${OLLAMA_HOST}
OLLAMA_MODEL_PREF=${DEFAULT_MODEL}
OLLAMA_MODEL_TOKEN_LIMIT=4096
EMBEDDING_ENGINE=native
VECTOR_DB=lancedb
EOF
    echo -e "${GREEN}Done. Default model: ${DEFAULT_MODEL} @ ${OLLAMA_HOST}${NC}"
fi

# ── Show installed models ─────────────────────────────────────
if [[ -f "$MODELS_FILE" ]]; then
    echo ""
    echo "Installed models:"
    while IFS='|' read -r local_name display_name label _; do
        tag=""
        [[ "$label" == "UNCENSORED" ]] && tag="${RED}[UNCENSORED]${NC}"
        [[ "$label" == "CUSTOM" ]] && tag="${GREEN}[CUSTOM]${NC}"
        [[ -z "$tag" ]] && tag="${CYAN}[STANDARD]${NC}"
        echo -e "  - ${display_name} ${tag}"
    done < "$MODELS_FILE"
    echo ""
fi

# ── Sanity checks ─────────────────────────────────────────────
if [[ ! -x "$OLLAMA_BIN" ]]; then
    echo -e "${RED}ERROR: Ollama binary not found at: $OLLAMA_BIN${NC}"
    echo "Please run install.sh first."
    exit 1
fi

if [[ ! -f "$APPIMAGE" ]]; then
    echo -e "${RED}ERROR: AnythingLLM AppImage not found at: $APPIMAGE${NC}"
    echo "Please run install.sh first."
    exit 1
fi

chmod +x "$APPIMAGE" 2>/dev/null || true

# ── Wipe hardware-dependent Electron caches only ──────────────
# NOTE: We do NOT delete config.json here — that contains user
# settings. Only GPU/Shader/Path caches that break across PCs.
ANYTHINGLLM_CACHE="$XDG_CONFIG_HOME/anythingllm-desktop"
rm -rf "$ANYTHINGLLM_CACHE/GPUCache"       2>/dev/null || true
rm -rf "$ANYTHINGLLM_CACHE/Cache"          2>/dev/null || true
rm -rf "$ANYTHINGLLM_CACHE/Code Cache"     2>/dev/null || true
rm -rf "$ANYTHINGLLM_CACHE/ShaderCache"    2>/dev/null || true

# ── Start Ollama Engine (background) ───────────────────────────
echo -e "${YELLOW}Starting Ollama Engine on ${OLLAMA_HOST}...${NC}"
"$OLLAMA_BIN" serve &>/dev/null &
OLLAMA_PID=$!

# Bump process priority if permitted (Linux equivalent of /Abovenormal)
renice -n -1 -p "$OLLAMA_PID" &>/dev/null || true

# ── Health check: poll API instead of blind sleep ─────────────
echo -en "${DGRAY}  Waiting for Ollama to be ready...${NC}"
MAX_WAIT=30
READY=false
for (( i=0; i<<MAX_WAIT; i++ )); do
    if curl -s "http://${OLLAMA_HOST}/api/tags" &>/dev/null; then
        echo -e "${GREEN} Ready!${NC}"
        READY=true
        break
    fi
    echo -n "."
    sleep 1
done

if ! $READY; then
    echo -e "${RED} Timeout!${NC}"
    echo -e "${RED}Ollama failed to start. Is port ${OLLAMA_PORT} blocked or in use?${NC}"
    exit 1
fi

# ── Start AnythingLLM ─────────────────────────────────────────
echo -e "${YELLOW}Starting AnythingLLM Interface...${NC}"

# Detect FUSE availability. If missing / broken, fallback to extract-and-run.
FUSE_OK=false
if command -v fusermount3 &>/dev/null || command -v fusermount &>/dev/null; then
    [[ -c /dev/fuse ]] && FUSE_OK=true
fi

launch_appimage() {
    "$APPIMAGE" \
        --user-data-dir="$STORAGE_DIR/anythingllm-desktop" \
        --no-sandbox \
        &>/dev/null &
    ANYTHINGLLM_PID=$!
}

if $FUSE_OK; then
    launch_appimage
    sleep 2
    # If the process died immediately, FUSE may still be broken (e.g. namespace restrictions)
    if ! kill -0 "$ANYTHINGLLM_PID" 2>/dev/null; then
        echo -e "${YELLOW}  FUSE launch failed, switching to extract-and-run...${NC}"
        APPIMAGE_EXTRACTED=1
        APPIMAGE_EXTRACT_AND_RUN=1 launch_appimage
    fi
else
    echo -e "${DGRAY}  FUSE not available, using extract-and-run mode...${NC}"
    APPIMAGE_EXTRACTED=1
    APPIMAGE_EXTRACT_AND_RUN=1 launch_appimage
fi

echo ""
echo -e "${CYAN}==================================================="
echo -e "   SYSTEM ONLINE: Your AI is running from USB!"
echo -e "===================================================${NC}"
echo ""
echo "  Ollama API:  http://${OLLAMA_HOST}"
echo "  Models dir:  $OLLAMA_MODELS"
echo ""
echo -e "${YELLOW}Keep this terminal open to keep the AI engine running!${NC}"
echo ""
echo -e "${RED}Press Enter to SHUT DOWN the AI safely...${NC}"
read -r

# Cleanup runs automatically via EXIT trap