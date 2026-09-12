# Pendrive_X — Portable AI on a USB Drive

**A fully private, portable, uncensored AI assistant that runs 100% from a USB flash drive.** No internet required after setup. No data leaves the drive. Works on **Windows**, **macOS**, and **Linux**.

> **6 curated models + custom GGUF support.** Pick one small model for old laptops or load them all on a 64 GB stick.

---

## Table of Contents

- [Features](#features)
- [Available Models](#available-models)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [How to Run](#how-to-run)
- [USB Drive Layout](#usb-drive-layout)
- [Switching Models](#switching-models)
- [Token Limit / Context Size](#token-limit--context-size)
- [Privacy & Portability](#privacy--portability)
- [Troubleshooting](#troubleshooting)
- [Bugs Fixed in this Revision](#bugs-fixed-in-this-revision)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **100% offline after install** — downloads once, runs forever without internet.
- **Zero host footprint** — no registry keys, no `AppData` leftovers, no admin required.
- **Cross-platform** — native launchers for Windows (`.bat`), macOS (`.command`), and Linux (`.sh`).
- **Multi-model** — install 1–6 presets or bring any HuggingFace `GGUF` URL.
- **Idempotent installer** — re-run to add models; already-downloaded files are skipped.
- **Safe shutdown** — PID-tracked Ollama + AnythingLLM, no orphan processes on the host.
- **Health checks** — launchers poll `http://127.0.0.1:<port>/api/tags` instead of blind `sleep`.

---

## Available Models

Choose during install (interactive menu: `1,3` or `all` or `1,c` for custom).

| # | Model | Size | Label | Strength |
|---|-------|------|-------|----------|
| 1 | **NemoMix Unleashed 12B** (`Q5_K_M`) | ~8.73 GB | `UNCENSORED` | Recommended — best uncensored quality |
| 2 | **Dolphin 2.9 Llama 3 8B** (`Q4_K_M`) | ~4.9 GB | `UNCENSORED` | Classic all-rounder |
| 3 | **Mistral 7B Instruct v0.3** | ~4.1 GB | `STANDARD` | Strong reasoning & coding |
| 4 | **Qwen 2.5 7B Instruct** | ~4.7 GB | `STANDARD` | Multilingual |
| 5 | **Llama 3.2 3B Instruct** | ~2.0 GB | `STANDARD` | Lightweight — fast on old PCs |
| 6 | **Phi-3.5 Mini 3.8B** | ~2.2 GB | `STANDARD` | Lightweight — good reasoning |
| C | **Custom GGUF** | varies | `CUSTOM` | Paste any `https://huggingface.co/.../resolve/.../*.gguf` |

> `UNCENSORED` = no content filters. `STANDARD` = normal safety guidelines.

Update the catalog in `install-core.ps1:30` / `linux/install-core.sh:80` if you need a different quantization.

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| USB size (1 lightweight model) | 16 GB exFAT | 16 GB |
| USB size (NemoMix 12B) | 16 GB | 32 GB |
| USB size (2–3 models) | 32 GB | 64 GB |
| USB size (all 6 presets ≈ 26 GB + engine 1 GB) | 64 GB | 64 GB |
| RAM (3B models) | 6 GB | 8 GB |
| RAM (7B models) | 8 GB | 16 GB |
| RAM (12B NemoMix) | 12 GB | 16 GB |
| CPU | x64, any modern | x64 with 4+ cores |
| Filesystem | **exFAT** (or ext4/NTFS) | exFAT — required for >4 GB files; FAT32 will fail |
| Network | Internet for first install only | — |

> **USB must be `exFAT`.** FAT32 has a 4 GB per-file limit and will corrupt the 7–8 GB GGUF downloads. The Linux `preflight-check.sh` detects this automatically. On Windows, right-click the drive → Format → `exFAT`.

---

## Quick Start

### Windows

1. Copy **all files** from this repo to the **root of your USB** (not a subfolder).
2. Double-click **`install.bat`** → pick models (e.g. `1` or `1,3` or `all`).
3. When the **AnythingLLM installer** pops up, click **Browse** and select `E:\anythingllm` (your USB path). Wait, then close it.
4. Done. Launch with **`start-windows.bat`** (or `optimiced.bat` for the hardened launcher).

### macOS

1. Copy all files to USB root.
2. Double-click **`start-mac.command`** — first run auto-downloads the macOS Ollama engine (~150 MB) and AnythingLLM (`AnythingLLMDesktop-Silicon.dmg`) directly to the USB. No Mac installation.
3. To pre-install models on a Mac, use a Windows/Linux PC first, or run `bash linux/install-core.sh` inside a Linux VM pointing at the mounted USB.

### Linux

```bash
# 1. Make scripts executable
chmod +x linux/preflight-check.sh linux/install.sh linux/install-core.sh linux/start-linux.sh

# 2. Validate the drive (checks space, FS, speed, removable detection)
bash linux/preflight-check.sh          # auto-detects USB
# or
bash linux/preflight-check.sh /media/$USER/MYUSB

# 3. Install (preflight launches this automatically if you confirm)
bash linux/install.sh
# or directly:
bash linux/install-core.sh /media/$USER/MYUSB

# 4. Launch
bash linux/start-linux.sh
```

---

## Detailed Setup

### What the installer does (6 steps)

1. **Model selection** — interactive menu, supports `1,3`, `all`, `c`/`custom`, and mixes like `1,3,c`.
2. **Folder creation** — `models/`, `ollama/`, `anythingllm/`, `anythingllm_data/`, `installer_data/`.
3. **Model downloads** — `curl` with `--retry 2` to temp `.part` files, verified by minimum byte size before `mv`.
4. **Modelfiles** — generates `models/Modelfile-<localName>` per model + legacy `models/Modelfile` + `installed-models.txt`.
5. **Ollama engine** — Windows ZIP / Linux `tar.zst` / macOS `darwin.zip`, extracted to `ollama/` (Windows/Linux) or `ollama_mac/` (macOS).
6. **AnythingLLM UI** — Windows: prompts manual install to USB; Linux: AppImage; macOS: DMG extracted to `anythingllm_mac/`.

Re-running the installer **never re-downloads** valid files (`file_is_valid` / `Test-DownloadedFile` checks). Use it to add models later.

### If a download fails

The script retries once automatically. If it still fails:

1. Copy the HuggingFace `.../resolve/main/*.gguf` URL shown in the error.
2. Download manually (browser or `curl -L -o models/file.gguf URL`).
3. Place the `.gguf` in `models/` on the USB.
4. Re-run `install.bat` / `install-core.sh` — it will detect and skip it.

### Custom models

Pick `C` at the menu, paste a direct `.gguf` URL, give a short name (auto-suffixed `-local`), and optionally a system prompt. Validation warns if URL lacks `.gguf` but lets you proceed with confirmation.

---

## How to Run

### Windows (`start-windows.bat`)

- Clears **only** `anythingllm-desktop/GPUCache|Cache|Code Cache|ShaderCache` (never `config.json`).
- Captures Ollama PID via PowerShell `Start-Process -PassThru`, polls `http://127.0.0.1:11434/api/tags` for 30 s, stores PID in `anythingllm_data/.session_pids`.
- Launches `AnythingLLM.exe --user-data-dir="%USB%\anythingllm_data"`.
- **Keep the black terminal open.** Press any key to shut down — kills only the USB's Ollama PID (+ path-verified fallback), never a host Ollama.

Alternative hardened launcher: **`optimiced.bat`** (Spanish UI) — dynamic port, `Get-CimInstance` (not deprecated `Get-WmiObject`), disk-space guard, priority `AboveNormal`, preserved token limit.

### macOS (`start-mac.command`)

- First run: downloads `ollama-darwin.zip` → `ollama_mac/`, and `AnythingLLMDesktop-Silicon.dmg` → `anythingllm_mac/AnythingLLM.app` via `hdiutil attach` (robust `/dev/diskN` parsing).
- Finds a free port 11434–11534 via `nc -z` / `lsof` / Python socket fallback (not `/dev/tcp`, which is absent on macOS).
- Sets `OLLAMA_MODELS`, `XDG_*_HOME` to USB paths. Polls API, clears hardware caches, launches `Contents/MacOS/AnythingLLM --user-data-dir=...` (or `open -a` fallback).
- `trap cleanup` on EXIT/INT/TERM/HUP; `xargs -r` safe.

### Linux (`linux/start-linux.sh`)

- Mirrors the macOS pattern: `OLLAMA_MODELS`, `XDG_*`, free-port scan, 30 s health poll, AppImage launch with `FUSE` detection + `APPIMAGE_EXTRACT_AND_RUN` fallback, `renice -n -1`.

---

## USB Drive Layout

**Windows** (after successful install):

```
E:\
├── install.bat                 ← Windows installer entry
├── install-core.ps1            ← Core logic (called by install.bat)
├── start-windows.bat           ← Main Windows launcher
├── optimiced.bat               ← Hardened alt launcher (dynamic port, PID tracking)
├── start-mac.command           ← macOS launcher (works from same USB)
├── linux/                      ← Linux scripts (also usable from Windows USB)
│   ├── install.sh
│   ├── install-core.sh
│   ├── preflight-check.sh
│   └── start-linux.sh
├── ollama/                     ← Windows/Linux engine
│   ├── ollama.exe (or ollama)
│   └── data/                   ← Ollama model storage (OLLAMA_MODELS)
├── ollama_mac/                 ← macOS engine (ollama binary / Ollama.app)
├── models/
│   ├── *.gguf                  ← Model weights
│   ├── Modelfile-<localName>   ← Per-model Ollama configs
│   ├── Modelfile               ← Legacy alias → first model
│   └── installed-models.txt    ← "local|Display Name|LABEL" per line
├── anythingllm/                ← Windows AnythingLLM install
├── anythingllm_mac/            ← macOS AnythingLLM.app
├── anythingllm_data/           ← ALL chats, settings, caches (portable!)
│   ├── storage/.env            ← LLM_PROVIDER, OLLAMA_BASE_PATH, MODEL_PREF
│   ├── config/  data/  cache/  ← XDG dirs (Linux/macOS)
│   └── anythingllm-desktop/    ← Electron profile + GPU caches
└── installer_data/             ← Temp installer files (auto-cleaned)
```

**Linux/macOS** paths are identical except `ollama_mac/` and `anythingllm_mac/` are used instead of `ollama/` + `anythingllm/`.

---

## Switching Models

In AnythingLLM: **Settings → LLM Provider → Ollama → Model** — pick any `*-local` name listed in `models/installed-models.txt`.

The `.env` default (`OLLAMA_MODEL_PREF`) is set to the first model you installed; changing it in the UI persists across restarts.

---

## Token Limit / Context Size

Default is `4096` tokens (good for 6–8 GB RAM). To increase:

1. Close the launcher.
2. Open `anythingllm_data/storage/.env` on the USB in a text editor.
3. Change `OLLAMA_MODEL_TOKEN_LIMIT=4096` → e.g. `8192` or `16384`.
4. Save and relaunch via `start-windows.bat` / `start-mac.command` / `linux/start-linux.sh`.

> **Preservation fix (this revision):** launchers now **preserve** a custom `OLLAMA_MODEL_TOKEN_LIMIT` instead of blindly overwriting it on every start. The installer also non-destructively patches `.env` if it already contains `LLM_PROVIDER=ollama`.

Re-running the *installer* (`install.bat` / `install-core.sh`) will still honor the existing `.env` if it already points at `ollama`; delete `.env` to force a reset.

---

## Privacy & Portability

- `STORAGE_DIR`, `APPDATA`, `LOCALAPPDATA`, `XDG_*` all point at `anythingllm_data/` on the USB.
- Electron is launched with `--user-data-dir=<USB>\anythingllm_data` — nothing under `%APPDATA%` or `~/Library/Application Support` on the host.
- `ollama/data` lives on the USB (`OLLAMA_MODELS`).
- Moving between PCs: hardware caches (`GPUCache`, `ShaderCache`, etc.) are wiped on launch to avoid `ENOENT` / GPU mismatch errors. Your chats and model settings stay intact.
- **Always eject safely** after the shutdown message appears.

---

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `FAT32 — 4 GB per-file limit will block` | Reformat USB as **exFAT** (Windows: right-click → Format → exFAT). |
| `No usable USB drive selected` (preflight) | Ensure USB is **mounted**; pass path explicitly: `bash linux/preflight-check.sh /media/$USER/USB`. |
| `File seems too small (… MB)` then `ERROR: Download failed` | Partial download — check free space, retry, or manual download to `models/`. |
| `AnythingLLM.exe not found` | Re-run `install.bat` and when prompted, **Browse → `E:\anythingllm`** (not `C:\Program Files`). |
| `Ollama failed to start on port …` / `Timeout` | Host Ollama already on 11434; launcher tries 11434–11534 but may collide if all busy. Close host Ollama or reboot. Check firewall. |
| `JavaScript error ENOENT` on new PC | Fixed in this revision — launcher wipes only GPU/Shader caches. Re-run `start-windows.bat`. |
| `FUSE launch failed` on Linux | AppImage fallback is automatic (`APPIMAGE_EXTRACT_AND_RUN=1`). Install `fuse3` / `libfuse2` for native speed, or keep extract-and-run. |
| `xargs: kill: No such process` on macOS exit | Fixed — now uses `xargs -r`. |
| Slow writes / AI loads 30+ s | USB 2.0 stick in USB 2.0 port. Use USB 3.0 drive in a blue USB 3.0 port. Check `preflight-check.sh` benchmark. |
| Nothing happens double-clicking `.command` on Mac | Right-click → Open, or `chmod +x start-mac.command` then double-click. Gatekeeper: `xattr -rc anythingllm_mac/AnythingLLM.app` is done automatically. |

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

```
Copyright ©️ All Right Reserved @Ifaz Md Zahin
```

---

```
                                   |
                                  |||
                                 |||||
                   |    |    |   |||||||
                  )_)  )_)  )_)   ~|~
                 )___))___))___)\  |
                )____)____)_____)\\|
              _____|____|____|_____\\\__
              \                       /
        ~^~^~~^~^~~^~^~~^~^~~^~^~~^~^~~^~^~~^~^~
                ~^~  Welcome aboard!  ~^~
        ~^~^~~^~^~~^~^~~^~^~~^~^~~^~^~~^~^~~^~^~
```
