SHELL := /bin/bash

install-server:
	@echo "Installing server..."
	./generate_unit_files.sh
	systemctl --user enable output/whisper.socket
	systemctl --user enable output/whisper.service

install-proxy:
	@echo "Installing proxy..."
	./generate_unit_files.sh
	systemctl --user enable output/whisper-proxy.service

install-client:
	@echo "Installing client..."
	./generate_client_request.sh
	export $$(cat .env | xargs) && /bin/bash -c "cp output/rofi-whisper-request $$BIN_PATH/rofi-whisper-request"
