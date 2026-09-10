## WASTE: Whisper Audio Service for Transcription and Ergonomics

This repo shares my (opinionated) setup in Linux to reduce keyboard use by making the most of speech to text, with [whisper](https://github.com/openai/whisper).

The main goal is to get speech to text anywhere:

* press a key
* rofi pops up with `auto` first, then one `repeat last in <lang>` entry per language (recording starts immediately)
* press enter to accept `auto` — letting whisper detect the language — **and** stop recording
* notification pops when transcription is ready
* whisper's output text becomes available in the clipboard

![recording](/recording.gif)

## How?

There are 3 main components:

* [whisper-asr](https://github.com/ahmetoner/whisper-asr-webservice) http **server** which receives audio files and transcribes using whisper
* **client** script to send audio files to the server

The setup relies on:

* [systemd](https://systemd.io) (to run server and proxy as services)
* [pacmd](https://linux.die.net/man/1/pacmd) (to list audio sources)
* [arecord](https://linux.die.net/man/1/arecord) (to record audio)
* [whisper-asr](https://github.com/ahmetoner/whisper-asr-webservice) (to transcribe audio files)
* [rofi](https://github.com/davatorium/rofi) (for user interaction, I use it on i3 wm)
* [dunstify](https://linuxcommandlibrary.com/man/dunstify) (to send notification once transcription is ready)
* [xclip](https://linux.die.net/man/1/xclip) (to copy text to clipboard)

## Setup

The two possible setups are:

* **Single Host**: one host running the **server** and the **client**. In other words, you run whisper in the same machine where you need a transcription.
* **Remote**: one host running the **server**, and another host running the **client**. In other words, you run whisper in a remote machine, and you access it from your local machine whenever you need a transcription.

### Setup Single Host

```mermaid
flowchart LR

 subgraph Host
    S[Server]
    C[Client]
 end

 C -->|http| S
```

Copy the file `.example-single-host-env` to `.env` and edit it to your needs:

```sh
AUDIO_DEVICE=alsa_input.pci-0000_03_00.6.analog-stereo # find your mic with 'pacmd list-sources`
LANGS="en,es" # comma separated list of languages offered as `repeat last in <lang>` retries; fresh recordings always use `auto`
BIN_PATH="/home/user/.local/bin" # path where the client script will be installed
PATTERNS_FILE="/home/user/.waste-patterns.sed" # path to sed patterns file
WHISPER_MODEL=medium # whisper model to use
```

* Run `make install-server` (generates and installs systemd units)
* Run `make install-client` (generates and installs client script)

Now you can bind the client script to a key in your window manager, for example in i3:

```sh
bindsym $mod+n exec $HOME/.local/bin/rofi-waste-request
```

### Setup Remote

```mermaid
flowchart LR

 subgraph "Remote Host"
    S["Server (whisper)"]
 end

 subgraph "Local (Client)"
    C[Client]
 end

 C -->|"POST /asr"| S
```

**NOTE ON SECURITY**: This is not meant to be used in a public network, as it does not use any encryption or auth of any kind. Do not expose the server to the internet. It is meant to be used in a private network, where you trust all the hosts.

**In the remote host:**

Copy the file `.example-server-env` to `.env` and edit it to your needs:

```sh
WASTE_ENDPOINT=192.168.1.10:29999 # ip and port where server will listen
WHISPER_MODEL=medium # whisper model to use
```

* Run `make install-server` (generates and installs systemd units, including proxy)

**In the local host:**

Copy the file `.example-client-env` to `.env` and edit it to your needs:

```sh
AUDIO_DEVICE=alsa_input.pci-0000_03_00.6.analog-stereo # find your mic with 'pacmd list-sources`
LANGS="en,es" # comma separated list of languages offered as `repeat last in <lang>` retries; fresh recordings always use `auto`
BIN_PATH="/home/user/.local/bin" # path where the client script will be installed
PATTERNS_FILE="/home/user/.waste-patterns.sed" # path to sed patterns file
WASTE_ENDPOINT="192.168.1.10:29999" # remote host IP and port where server is listening
```

* Run `make install-client` (generates and installs client script)

Now you can bind the client script to a key in your window manager, for example in i3:

```sh
bindsym $mod+n exec $HOME/.local/bin/rofi-whisper-request
```

## Troubleshooting

### Transcriptions suddenly slow (GPU dropped, CPU fallback)

After a system update — kernel, NVIDIA driver, or `nvidia-container-toolkit` — the container may silently fall back to CPU. Symptom: `nvidia-smi` on the host works fine, the container is up, but requests take much longer than usual.

**Diagnose:**

```sh
docker logs waste 2>&1 | grep -i cuda
# If you see: "CUDA initialization: CUDA unknown error ... Setting the available devices to be zero."
# then PyTorch can't talk to the GPU even though the container was started with --gpus all.

docker exec waste ls -l /dev/nvidia-uvm /dev/nvidia-uvm-tools
ls -l /dev/nvidia-uvm /dev/nvidia-uvm-tools
# Compare major numbers. If they differ, the CDI spec is stale.

nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
# When healthy, the container's python process should appear here using several GiB of VRAM.
```

**Fix:** regenerate the CDI spec, then restart the container.

```sh
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
systemctl --user restart waste.service
```

The `nvidia` Docker runtime on this setup uses CDI mode (`/etc/nvidia-container-runtime/config.toml` → `mode = "cdi"`), which reads `/etc/cdi/nvidia.yaml` on every container start. If that file was generated before the kernel's `nvidia-uvm` major number settled, the device nodes injected into the container point at the wrong driver and CUDA init fails. Regenerating writes the current host majors and the next start works.

**Why it recurs across reboots:** the `nvidia-uvm` major number is allocated dynamically and can change on every boot, while `/etc/cdi/nvidia.yaml` is static — so a spec generated on one boot goes stale on the next.

**Permanent fix (installed):** `nvidia-cdi-refresh.service` (in this repo) is a root systemd oneshot that regenerates the CDI spec before `docker.service` on every boot. Install once:

```sh
sudo cp nvidia-cdi-refresh.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nvidia-cdi-refresh.service
```

With it enabled you should never need the manual regenerate above again.

## Uninstall

Run `make uninstall`.
