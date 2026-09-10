# AGENTS.md

Orientation notes for agents working in this repo. Read `README.md` first for the user-facing description; this file covers what isn't obvious from the code.

## What this is

A personal Linux speech-to-text setup. A whisper-asr Docker container (`onerahmet/openai-whisper-asr-webservice:latest-gpu`) runs as a long-lived service exposing port 29999; a small client script records audio with `arecord`, POSTs `/asr`, and pipes the transcription to the clipboard via `xclip`.

## Build / install pipeline

`make` is the only entry point. Don't edit generated files directly without also editing the template:

- `tpl_waste.service`, `tpl_waste-proxy.service`, `tpl_rofi-waste-request` → envsubst with `.env` vars → `output/*`
- `generate_unit_files.sh` does the substitution for the systemd units
- `generate_client_request.sh` does it for the rofi client script
- `make install-server` regenerates units and runs `systemctl --user enable output/waste.service`
- `make install-client` regenerates the client script and copies it to `$BIN_PATH`

If you change a `tpl_*` file, run `./generate_unit_files.sh` (or `make install-server`) to refresh `output/`. For an iteration-tight loop on a unit that's already installed, edit *both* the template and `output/<unit>.service` so the running unit reflects your change without forcing a reinstall — but never let them drift permanently.

## Service shape

The whisper server runs as a **user-mode** systemd unit, not system-mode:

- File: `~/.config/systemd/user/waste.service` → symlink to `output/waste.service`
- Always `systemctl --user ...`, never plain `systemctl`
- `systemctl status waste` (system-mode) returns "Unit not found" — that's expected, not a bug

The unit just runs `docker run --gpus all ... onerahmet/openai-whisper-asr-webservice:latest-gpu`. State lives entirely in the container; the model cache is bind-mounted from `~/.cache/whisper`.

## GPU stack

This host uses NVIDIA + Docker via CDI:

- `/etc/nvidia-container-runtime/config.toml` has `mode = "cdi"`
- `--gpus all` therefore consults `/etc/cdi/nvidia.yaml`, not the legacy `nvidia-container-cli` mknod path
- If the CDI spec is stale (generated before kernel module majors settled), device nodes injected into the container point at the wrong driver and CUDA fails silently — PyTorch falls back to CPU, requests get ~10x slower
- The `nvidia-uvm` major is allocated dynamically and can change on every reboot, so a static `/etc/cdi/nvidia.yaml` goes stale. `nvidia-cdi-refresh.service` (in this repo, installed to `/etc/systemd/system/`) regenerates the spec before `docker.service` each boot to prevent this. If a user reports it broke "after a reboot", check that this unit is enabled and active (`systemctl is-active nvidia-cdi-refresh.service`)
- Recovery for one boot: `sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml` then restart the unit. See README "Troubleshooting" for the diagnostic flow

When investigating slowness, always check `nvidia-smi --query-compute-apps=...` — the container's python should be listed with multi-GiB VRAM. If it isn't, the container is on CPU regardless of what `--gpus all` and `docker inspect` claim.

## Things that look like bugs but aren't

- `output/` files diverge from `tpl_*` after envsubst — by design (env interpolation)
- `ExecStartPre=-/usr/bin/docker stop waste` and `... rm waste` exiting non-zero on first start — the leading `-` makes failure non-fatal; expected when no prior container exists
