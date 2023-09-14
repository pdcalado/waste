# WASTE: Whisper Audio Service for Transcription and Ergonomics

This repo shares my setup to reduce keyboard use by making the most of speech to text, with [whisper](https://github.com/openai/whisper).

There are 3 main components:
* python server bound to a Unix socket, which receives audio files and transcribes using whisper
* a proxy service using socat to expose server, in case you need remote access
* a client script to send audio files to the server

The setup relies on:
* systemd (to run server and proxy as services)
* pacmd (to list audio sources)
* arecord (to record audio)
* socat (to expose server)
* whisper (to transcribe audio files)
* rofi (for user interaction, I use it on i3 wm)
* dunstify (to send notification once transcription is ready)
