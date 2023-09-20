SHELL := /bin/bash

prepare:
	@echo "Preparing..."
	mkdir -p output

install-server: prepare
	@echo "Installing server..."
	./generate_unit_files.sh
	systemctl --user enable output/waste.socket
	systemctl --user enable output/waste.service

install-proxy: prepare
	@echo "Installing proxy..."
	./generate_unit_files.sh
	systemctl --user enable output/waste-proxy.service

install-client: prepare
	@echo "Installing client..."
	./generate_client_request.sh
	export $$(cat .env | xargs) && /bin/bash -c "cp output/rofi-waste-request $$BIN_PATH/rofi-waste-request"

uninstall:
	@echo "Uninstalling..."
	systemctl --user disable waste.socket || true
	systemctl --user disable waste.service || true
	systemctl --user disable waste-proxy.service || true
	export $$(cat .env | xargs) && /bin/bash -c "rm $$BIN_PATH/rofi-waste-request -f"

clean:
	@echo "Cleaning..."
	rm output -rf