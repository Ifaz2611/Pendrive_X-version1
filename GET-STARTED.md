# Pendrive_X Quick Start

Pendrive_X lets you run a private AI assistant from a USB drive using Ollama and AnythingLLM.

After the first installation, your models, chats, settings, and application data are stored on the USB drive.

## Before you begin

You need:

- A USB drive formatted as **exFAT**, NTFS, or a Linux filesystem that supports files larger than 4 GB.
- Internet access for the first installation.
- At least **16 GB** of free space for one small model.
- At least **32 GB** for a larger model.
- At least **64 GB** if you want to install all preset models.
- A modern 64-bit computer.

Do not use FAT32. FAT32 cannot store the larger GGUF model files.

## 1. Copy the project to your USB drive

Copy all files and folders from this project to the **root** of the USB drive.

The launchers should be directly visible on the drive, for example:

```text
E:\
├── install.bat
├── start-windows.bat
├── start-mac.command
├── models\
└── linux\
```

Do not put the project inside another folder unless you also run the scripts from that folder.

## 2. Install on Windows

1. Open the USB drive in File Explorer.
2. Double-click `install.bat`.
3. Choose a model:
   - `1` for the recommended larger model.
   - `3` for a good coding model.
   - `5` or `6` for a lightweight model.
   - `1,3` to install multiple models.
   - `all` to install every preset model.
   - `c` to download a custom GGUF model.
4. Wait while the model, Ollama, and AnythingLLM are downloaded.
5. If the AnythingLLM installer opens, choose a location inside the USB drive:

   ```text
   E:\anythingllm
   ```

6. When installation finishes, double-click `start-windows.bat`.

For an additional Windows launcher with extra disk and process checks, you can use `optimiced.bat`.

## 3. Install on Linux

Open a terminal and replace `/media/$USER/MYUSB` with the actual USB path if necessary:

```bash
cd /media/$USER/MYUSB
chmod +x linux/*.sh doctor.sh
bash linux/preflight-check.sh
```

The preflight check verifies the USB filesystem, available space, removable-drive detection, and read/write speed. Confirm the installation when prompted.

To install directly:

```bash
bash linux/install-core.sh /media/$USER/MYUSB
```

Then start Pendrive_X:

```bash
bash linux/start-linux.sh
```

If the USB is mounted somewhere else, pass its path explicitly:

```bash
bash linux/start-linux.sh /path/to/usb
```

Linux may require these tools:

```text
curl, tar, zstd, dd, df, lsblk, awk, findmnt
```

## 4. Use macOS

1. Copy the project to the USB drive.
2. Open Terminal.
3. Make the launcher executable:

   ```bash
   cd /Volumes/YOUR_USB_NAME
   chmod +x start-mac.command
   ```

4. Start it:

   ```bash
   ./start-mac.command
   ```

On the first run, the launcher downloads the macOS versions of Ollama and AnythingLLM directly to the USB drive. This may take several minutes and requires internet access.

If macOS blocks the launcher, right-click `start-mac.command`, choose **Open**, and confirm. The AnythingLLM application may also require permission the first time it runs.

## 5. Starting the AI after installation

Use the launcher for your operating system:

| Operating system | Launcher |
|---|---|
| Windows | `start-windows.bat` |
| Linux | `bash linux/start-linux.sh` |
| macOS | `./start-mac.command` |

Keep the terminal window open while using the AI. It runs the Ollama engine in the background and uses a local address such as:

```text
http://127.0.0.1:11434
```

AnythingLLM should open automatically.

## 6. Choosing a model

In AnythingLLM:

1. Open **Settings**.
2. Open the **LLM** or **LLM Provider** section.
3. Select **Ollama**.
4. Choose one of the installed models.
5. Save the settings.

Installed models are listed in:

```text
models\installed-models.txt
```

You can also change the default model in:

```text
anythingllm_data\storage\.env
```

The relevant setting is:

```text
OLLAMA_MODEL_PREF=model-name-local
```

## 7. Changing the token limit

The default context size is 4096 tokens. To increase it:

1. Close Pendrive_X.
2. Open `anythingllm_data/storage/.env` on the USB.
3. Change this value:

   ```text
   OLLAMA_MODEL_TOKEN_LIMIT=4096
   ```

   For example:

   ```text
   OLLAMA_MODEL_TOKEN_LIMIT=8192
   ```

4. Save the file and start Pendrive_X again.

Higher values require more RAM. If the computer becomes slow or the model stops responding, use a lower value.

## 8. Adding another model later

Run the installer again and select the additional model. Existing valid downloads are skipped.

On Windows:

```text
install.bat
```

On Linux:

```bash
bash linux/install-core.sh /path/to/usb
```

You can also choose `c` or `custom` and provide a direct `.gguf` URL from Hugging Face.

## 9. Shutting down safely

When you finish using the AI:

1. Return to the terminal window running the launcher.
2. Press a key on Windows, or press **Enter** on Linux/macOS.
3. Wait for the shutdown message.
4. Safely eject the USB drive.

Do not unplug the USB while the AI is still running. Chats and settings are saved on the drive.

## Troubleshooting

### The installer says FAT32 is not supported

Back up the USB, reformat it as **exFAT**, and copy the project back to it. Formatting erases the drive.

### AnythingLLM is missing

Run the installer again. On Windows, make sure the AnythingLLM installation location is inside the USB drive:

```text
E:\anythingllm
```

### Ollama does not start

- Close another Ollama instance running on the computer.
- Restart the launcher.
- Make sure the USB has free space.
- Check the launcher logs in `anythingllm_data/logs`.

### The AI is slow

- Use model `5` or `6`.
- Reduce the token limit to 4096.
- Use a USB 3.0 or newer port.
- Close other applications to free RAM.

### You need diagnostics

On Windows, run:

```text
doctor.bat
```

On Linux or macOS, run:

```bash
bash doctor.sh
```

## Privacy note

Pendrive_X is designed to run locally after setup. Models, chats, settings, and logs are stored on the USB drive. Anyone who obtains the USB may be able to read the stored data, so use BitLocker, VeraCrypt, or another encryption method if the drive contains sensitive information.
