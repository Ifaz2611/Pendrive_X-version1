#!/bin/bash
# ================================================================
# PENDRIVE_X AI - MAC LAUNCHER [HARDENED]
# ================================================================
# Just double-click this file on any Mac to start your portable AI.
# Everything runs from the USB drive. Nothing is installed on the Mac.
# ================================================================

set -uo pipefail

# ── Colour codes (Modern High-Contrast Palette) ──────────────────
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
CYAN='\033[1;96m'
MAGENTA='\033[1;95m'
DGRAY='\033[2;90m'
BOLD='\033[1m'
NC='\033[0m'   # reset

# ── Terminal Banner & Initialization ───────────────────────────
echo -e "\n${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${CYAN}┃${NC}  ${MAGENTA} PENDRIVE_X AI${NC} ${DGRAY}|${NC} ${YELLOW}macOS Portable Launcher${NC}           ${CYAN}┃${NC}"
echo -e "${CYAN}┃${NC}  ${DGRAY}Everything runs from USB • Zero host installation${NC}  ${CYAN}┃${NC}"
echo -e "${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}\n"
echo -e "${DGRAY}[SYS]${NC} Initializing portable runtime environment..."
echo -e "${DGRAY}[SYS]${NC} Loading USB-mounted configuration..."

cd "$(dirname "$0")"
USB_DIR=$(pwd)
MAC_OLLAMA_DIR="$USB_DIR/ollama_mac"
DATA_DIR="$USB_DIR/ollama/data"
MODELS_DIR="$USB_DIR/models"
STORAGE_DIR="$USB_DIR/anythingllm_data"

OLLAMA_PID=""
ANYTHINGLLM_PID=""
OLLAMA_PORT="11434"
OLLAMA_BIN=""

# ── Cleanup function ──────────────────────────────────────────
cleanup() {
    echo ""
    echo -e "${YELLOW}[SHUTDOWN]${NC} Shutting down AI Engine..."
    [[ -n "$ANYTHINGLLM_PID" ]] && kill "$ANYTHINGLLM_PID" 2>/dev/null || true
    [[ -n "$OLLAMA_PID" ]] && kill "$OLLAMA_PID" 2>/dev/null || true
    [[ -n "$ANYTHINGLLM_PID" ]] && wait "$ANYTHINGLLM_PID" 2>/dev/null || true
    [[ -n "$OLLAMA_PID" ]] && wait "$OLLAMA_PID" 2>/dev/null || true
    # Kill by path to avoid hitting a host Ollama
    pgrep -f "$MAC_OLLAMA_DIR" | xargs kill -9 2>/dev/null || true
    echo -e "${GREEN}[EXITO]${NC} AI shut down. You may safely eject the USB."
}
trap cleanup EXIT INT TERM HUP

echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Launching PENDRIVE_X Engine for Mac...${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 1: Download Mac Ollama Engine (first time only)
# ═══════════════════════════════════════════════════════════════
echo -e "${DGRAY}[STEP 1/7]${NC} Checking Ollama Engine on USB..."
if [ ! -d "$MAC_OLLAMA_DIR/Ollama.app" ] && [ ! -f "$MAC_OLLAMA_DIR/ollama" ]; then
    echo -e "${YELLOW}[FIRST RUN]${NC} Downloading the AI Engine for macOS..."
    echo -e "${DGRAY}→ Fetching from official Ollama release channel...${NC}"
    mkdir -p "$MAC_OLLAMA_DIR"
    curl -fL --progress-bar --retry 2 --retry-delay 5 \
        "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.zip" \
        -o "$MAC_OLLAMA_DIR/ollama-darwin.zip"
    echo -e "${DGRAY}→ Extracting engine binaries...${NC}"
    unzip -o -q "$MAC_OLLAMA_DIR/ollama-darwin.zip" -d "$MAC_OLLAMA_DIR/"
    rm -f "$MAC_OLLAMA_DIR/ollama-darwin.zip"
    
    if [ -f "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama" ]; then
        chmod +x "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama"
    elif [ -f "$MAC_OLLAMA_DIR/ollama" ]; then
        chmod +x "$MAC_OLLAMA_DIR/ollama"
    fi
    echo -e "${GREEN}[✓]${NC} Mac Engine Setup Complete!"
    echo ""
else
    echo -e "${GREEN}[✓]${NC} Ollama Engine already present on USB"
fi

# Determine binary path
if [ -f "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama" ]; then
    OLLAMA_BIN="$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama"
elif [ -f "$MAC_OLLAMA_DIR/ollama" ]; then
    OLLAMA_BIN="$MAC_OLLAMA_DIR/ollama"
else
    echo -e "${RED}[ERROR]${NC} Could not find the Ollama binary on the USB drive!"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# STEP 2: Download AnythingLLM (first time only)
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${DGRAY}[STEP 2/7]${NC} Checking AnythingLLM Interface on USB..."
if [ ! -d "$USB_DIR/anythingllm_mac/AnythingLLM.app" ]; then
    echo -e "${YELLOW}[FIRST RUN]${NC} Downloading AnythingLLM directly to USB..."
    echo -e "${DGRAY}→ NO installation on the Mac! Everything stays on the drive.${NC}"
    mkdir -p "$USB_DIR/anythingllm_mac"
    
    echo -e "${DGRAY}→ Fetching Silicon-optimized DMG from AnythingLLM CDN...${NC}"
    curl -fL --progress-bar --retry 2 --retry-delay 5 \
        "https://cdn.anythingllm.com/latest/AnythingLLMDesktop-Silicon.dmg" \
        -o "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg"
    
    echo -e "${DGRAY}→ Extracting AnythingLLM to USB (please wait)...${NC}"
    
    # Hardened DMG mount: capture the actual device node
    MOUNT_OUTPUT=$(hdiutil attach -nobrowse "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg" 2>&1)
    DEV_NODE=$(echo "$MOUNT_OUTPUT" | grep -o '^/dev/disk[0-9]*s[0-9]*')
    MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/[^[:space:]]*' | tail -1)
    
    if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
        echo -e "${RED}[ERROR]${NC} Failed to mount DMG. Output:"
        echo "$MOUNT_OUTPUT"
        rm -f "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg"
        exit 1
    fi
    
    if [ ! -d "$MOUNT_DIR/AnythingLLM.app" ]; then
        echo -e "${RED}[ERROR]${NC} AnythingLLM.app not found inside DMG at $MOUNT_DIR"
        hdiutil detach "$DEV_NODE" 2>/dev/null || true
        rm -f "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg"
        exit 1
    fi
    
    echo -e "${DGRAY}→ Copying application bundle to USB...${NC}"
    cp -R "$MOUNT_DIR/AnythingLLM.app" "$USB_DIR/anythingllm_mac/"
    hdiutil detach "$DEV_NODE" 2>/dev/null || hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
    rm -f "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg"
    
    # Remove Apple quarantine so it runs from USB
    xattr -rc "$USB_DIR/anythingllm_mac/AnythingLLM.app" 2>/dev/null || true
    
    echo -e "${GREEN}[✓]${NC} AnythingLLM extracted and ready!"
else
    echo -e "${GREEN}[✓]${NC} AnythingLLM Interface already present on USB"
fi

# ═══════════════════════════════════════════════════════════════
# STEP 3: Find free port + path virtualization
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${DGRAY}[STEP 3/7]${NC} Configuring portable runtime paths..."

# Lock all data paths to the USB drive
export OLLAMA_MODELS="$DATA_DIR"
mkdir -p "$STORAGE_DIR/storage"

# Find a free port to avoid collision with host Ollama
echo -e "${DGRAY}→ Scanning for available port (11434-11534)...${NC}"
for port in $(seq 11434 11534); do
    (exec 2>/dev/null; echo >/dev/tcp/127.0.0.1/$port) || { OLLAMA_PORT="$port"; break; }
done
export OLLAMA_HOST="127.0.0.1:$OLLAMA_PORT"
echo -e "${GREEN}[✓]${NC} Ollama port allocated: ${CYAN}$OLLAMA_PORT${NC}"

# XDG overrides for Electron/AnythingLLM
export XDG_CONFIG_HOME="$STORAGE_DIR/config"
export XDG_DATA_HOME="$STORAGE_DIR/data"
export XDG_CACHE_HOME="$STORAGE_DIR/cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
echo -e "${DGRAY}[✓]${NC} Virtualized config/data/cache paths set to USB"

# ═══════════════════════════════════════════════════════════════
# STEP 4: Configure AnythingLLM .env
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${DGRAY}[STEP 4/7]${NC} Validating AnythingLLM configuration..."
DEFAULT_MODEL="nemomix-local"
if [ -f "$MODELS_DIR/installed-models.txt" ]; then
    DEFAULT_MODEL=$(head -n 1 "$MODELS_DIR/installed-models.txt" | cut -d '|' -f 1)
fi

ENV_FILE="$STORAGE_DIR/storage/.env"
NEEDS_FIX=0
if [ ! -f "$ENV_FILE" ]; then
    NEEDS_FIX=1
elif ! grep -q "OLLAMA_BASE_PATH=http://127.0.0.1:$OLLAMA_PORT" "$ENV_FILE" 2>/dev/null; then
    NEEDS_FIX=1
elif grep -q "LLM_PROVIDER=anythingllm_ollama" "$ENV_FILE" 2>/dev/null; then
    NEEDS_FIX=1
fi

if [ "$NEEDS_FIX" = "1" ]; then
    echo -e "${YELLOW}[CONFIG]${NC} Updating AnythingLLM to use external Ollama engine..."
    cat > "$ENV_FILE" << EOF
LLM_PROVIDER=ollama
OLLAMA_BASE_PATH=http://127.0.0.1:$OLLAMA_PORT
OLLAMA_MODEL_PREF=$DEFAULT_MODEL
OLLAMA_MODEL_TOKEN_LIMIT=4096
EMBEDDING_ENGINE=native
VECTOR_DB=lancedb
EOF
    echo -e "${GREEN}[✓]${NC} Configured: ${CYAN}$DEFAULT_MODEL${NC} @ port ${CYAN}$OLLAMA_PORT${NC}"
else
    echo -e "${GREEN}[✓]${NC} Configuration already valid"
fi

# ═══════════════════════════════════════════════════════════════
# STEP 5: Show installed models
# ═══════════════════════════════════════════════════════════════
if [ -f "$MODELS_DIR/installed-models.txt" ]; then
    echo ""
    echo -e "${CYAN}📦 Installed Models on USB:${NC}"
    echo -e "${DGRAY}────────────────────────────────────────${NC}"
    while IFS="|" read -r local_name nice_name tag; do
        if [ -n "$nice_name" ]; then
            echo -e "  ${GREEN}•${NC} $nice_name ${DGRAY}[$tag]${NC}"
        fi
    done < "$MODELS_DIR/installed-models.txt"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════
# STEP 6: Start Ollama Engine (background)
# ═══════════════════════════════════════════════════════════════
echo -e "${DGRAY}[STEP 6/7]${NC} Starting Ollama Engine from USB..."
echo -e "${DGRAY}→ Launching on $OLLAMA_HOST${NC}"
"$OLLAMA_BIN" serve >/dev/null 2>&1 &
OLLAMA_PID=$!

# Bump priority (renice is best-effort, no sudo needed)
renice -n -1 -p "$OLLAMA_PID" 2>/dev/null || true

# ── Health check: poll API instead of blind sleep ─────────────
echo -n -e "${DGRAY}→ Waiting for engine"
MAX_WAIT=30
READY=false
for (( i=0; i<MAX_WAIT; i++ )); do
    if curl -s "http://127.0.0.1:$OLLAMA_PORT/api/tags" >/dev/null 2>&1; then
        echo -e " ${GREEN}[OK]${NC} ${BOLD}Motor activo.${NC}"
        READY=true
        break
    fi
    echo -n "."
    sleep 1
done

if ! $READY; then
    echo ""
    echo -e "${RED}[ERROR]${NC} Ollama failed to start on port $OLLAMA_PORT within 30s."
    exit 1
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN} SYSTEM ONLINE: Your AI is running from USB!${NC}  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${DGRAY}Ollama API: http://127.0.0.1:$OLLAMA_PORT${NC}          ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 7: Launch AnythingLLM
# ═══════════════════════════════════════════════════════════════
echo -e "${DGRAY}[STEP 7/7]${NC} Launching AI Interface from USB..."

# Wipe ONLY hardware-dependent caches (NOT config.json!)
ANYTHINGLLM_CACHE="$XDG_CONFIG_HOME/anythingllm-desktop"
rm -rf "$ANYTHINGLLM_CACHE/GPUCache" 2>/dev/null || true
rm -rf "$ANYTHINGLLM_CACHE/Cache" 2>/dev/null || true
rm -rf "$ANYTHINGLLM_CACHE/Code Cache" 2>/dev/null || true
rm -rf "$ANYTHINGLLM_CACHE/ShaderCache" 2>/dev/null || true
echo -e "${DGRAY}[✓]${NC} Hardware caches cleared for portability"

# Launch AnythingLLM from USB
echo -e "${DGRAY}→ Opening AnythingLLM.app with USB-mounted user data...${NC}"
open -a "$USB_DIR/anythingllm_mac/AnythingLLM.app" --args --user-data-dir="$STORAGE_DIR" >/dev/null 2>&1 &

# Capture PID (give it a moment to register)
sleep 2
ANYTHINGLLM_PID=$(pgrep -f "AnythingLLM.app" | head -1)
[[ -n "$ANYTHINGLLM_PID" ]] && echo -e "${GREEN}[✓]${NC} Interface PID: ${CYAN}$ANYTHINGLLM_PID${NC}"

echo ""
echo -e "${YELLOW}💡 TIP:${NC} Keep this terminal open while you chat!"
echo -e "${DGRAY}────────────────────────────────────────────────────${NC}"
echo -e "  Press ${BOLD}[ENTER]${NC} to shut down the AI safely."
echo -e "${DGRAY}────────────────────────────────────────────────────${NC}"
echo ""

# Wait for user
read -p "Hit [ENTER] to turn off the Engine..."

# Cleanup runs automatically via EXIT trap