# Makefile for mpv_audio_kit libmpv builds

.PHONY: help android ios linux windows docker-image

help:
	@echo "Usage:"
	@echo "  make android       - Build libmpv for Android (arm64-v8a)"
	@echo "  make ios           - Build libmpv for iOS (Universal Framework)"
	@echo "  make macos         - Build libmpv for macOS"
	@echo "  make linux         - Build libmpv for Linux (requires Docker)"
	@echo "  make windows       - Build libmpv for Windows (requires Docker)"
	@echo ""
	@echo "Docker tools:"
	@echo "  make docker-image  - Build the Docker build environment image"

# Native/NDK builds (run directly on macOS)
android:
	@chmod +x scripts/build_libmpv_android.sh
	ABIS="arm64-v8a" ./scripts/build_libmpv_android.sh

ios:
	@chmod +x scripts/build_libmpv_ios.sh
	./scripts/build_libmpv_ios.sh

macos:
	@chmod +x scripts/build_libmpv_macos.sh
	./scripts/build_libmpv_macos.sh

# Docker-based builds for Linux and Windows
docker-image:
	docker build -t mpv-build-env scripts/docker/

linux: docker-image
	docker run --rm -v "$(shell pwd)":/src -w /src mpv-build-env ./scripts/build_libmpv_linux.sh

windows: docker-image
	docker run --rm -v "$(shell pwd)":/src -w /src mpv-build-env ./scripts/build_libmpv_windows.sh
