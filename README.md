## WASTE: Whisper Audio Service for Transcription and Ergonomics

This repo shares my setup to reduce keyboard use by making the most of speech to text, with [whisper](https://github.com/openai/whisper).

The main goal is to get speech to text anywhere:
* press a key
* rofi pops up with language selection (recording starts immediately)
* press enter to choose language **and** stop recording
* notification pops when transcription is ready
* whisper's output text becomes available in the clipboard

## How?

There are 3 main components:
* python server bound to a Unix socket, which receives audio files and transcribes using whisper
* proxy service using socat to expose server, in case you need remote access
* client script to send audio files to the server

The setup relies on:
* systemd (to run server and proxy as services)
* pacmd (to list audio sources)
* arecord (to record audio)
* socat (to expose server)
* whisper (to transcribe audio files)
* rofi (for user interaction, I use it on i3 wm)
* dunstify (to send notification once transcription is ready)
* xclip (to copy text to clipboard)