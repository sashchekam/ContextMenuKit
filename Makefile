# Commands for agents and CI. People can just open Example/ContextMenuKitExample.xcodeproj:
# Cmd+R runs the example, Cmd+U runs the package tests.

SIMULATOR_NAME ?= ContextMenuKit-iPhone-17-Pro
SIMULATOR_DEVICE_TYPE ?= com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro
SIMULATOR_RUNTIME ?= com.apple.CoreSimulator.SimRuntime.iOS-26-3
DESTINATION = platform=iOS Simulator,name=$(SIMULATOR_NAME)

EXAMPLE_PROJECT = Example/ContextMenuKitExample.xcodeproj
EXAMPLE_SCHEME = ContextMenuKitExample
EXAMPLE_BUNDLE_ID = dev.contextmenukit.example
DERIVED_DATA = .build/ExampleDerivedData
PRODUCTS = Build/Products/Debug-iphonesimulator
XCODEBUILD = xcodebuild -scheme $(EXAMPLE_SCHEME) -destination '$(DESTINATION)' -quiet

# Every demo of the example, see Demo.swift.
DEMOS ?= free-views chat files tall-preview long-menu more-button custom-items accessories styles lifecycle swiftui
SCREENSHOTS_DIR = .build/screenshots
# The example presents the menu 1 s after launch, then the presentation animation runs.
SCREENSHOT_DELAY = 3

API_DIR = .build/api
API_DUMP = xcrun swift-api-digester -dump-sdk -module ContextMenuKit \
	-sdk "$$(xcrun --sdk iphonesimulator --show-sdk-path)" -target arm64-apple-ios15.0-simulator

.PHONY: simulator test example run-example screenshots api-diff lint clean

# Snapshot references depend on the device and the iOS version, so tests always run on this simulator.
simulator:
	@xcrun simctl list devices | grep -q "$(SIMULATOR_NAME) (" || \
		xcrun simctl create "$(SIMULATOR_NAME)" $(SIMULATOR_DEVICE_TYPE) $(SIMULATOR_RUNTIME)

# The example scheme's Test action runs the package tests, same as Cmd+U in Xcode.
test: simulator
	$(XCODEBUILD) -project $(EXAMPLE_PROJECT) -derivedDataPath $(DERIVED_DATA) test

example: simulator
	$(XCODEBUILD) -project $(EXAMPLE_PROJECT) -derivedDataPath $(DERIVED_DATA) build

# Installs and launches the example. Extra launch arguments: make run-example ARGS="-demo chat -autoPresentMenu YES"
run-example: example
	xcrun simctl boot "$(SIMULATOR_NAME)" 2>/dev/null || true
	open -a Simulator
	xcrun simctl install "$(SIMULATOR_NAME)" $(DERIVED_DATA)/$(PRODUCTS)/ContextMenuKitExample.app
	xcrun simctl launch --terminate-running-process "$(SIMULATOR_NAME)" $(EXAMPLE_BUNDLE_ID) $(ARGS)

# Opens each demo with its menu presented and saves .build/screenshots/<demo>.png.
# One demo: make screenshots DEMOS=chat
screenshots: example
	xcrun simctl boot "$(SIMULATOR_NAME)" 2>/dev/null || true
	xcrun simctl bootstatus "$(SIMULATOR_NAME)" >/dev/null
	xcrun simctl install "$(SIMULATOR_NAME)" $(DERIVED_DATA)/$(PRODUCTS)/ContextMenuKitExample.app
	mkdir -p $(SCREENSHOTS_DIR)
	@for demo in $(DEMOS); do \
		xcrun simctl launch --terminate-running-process "$(SIMULATOR_NAME)" $(EXAMPLE_BUNDLE_ID) \
			-demo $$demo -autoPresentMenu YES >/dev/null || exit 1; \
		sleep $(SCREENSHOT_DELAY); \
		xcrun simctl io "$(SIMULATOR_NAME)" screenshot --type=png $(SCREENSHOTS_DIR)/$$demo.png 2>/dev/null || exit 1; \
		echo "$(SCREENSHOTS_DIR)/$$demo.png"; \
	done

# Breaking changes of the public API since BASE, a tag or a branch: make api-diff BASE=0.1.0
# Builds BASE from `git archive` next to the working tree. Additions are not listed.
api-diff: example
	@test -n "$(BASE)" || { echo "Usage: make api-diff BASE=<tag or branch>"; exit 1; }
	rm -rf $(API_DIR)
	mkdir -p $(API_DIR)/base
	git archive --format=tar "$(BASE)" | tar -x -C $(API_DIR)/base
	$(XCODEBUILD) -project $(API_DIR)/base/$(EXAMPLE_PROJECT) -derivedDataPath $(API_DIR)/BaseDerivedData build
	$(API_DUMP) -I $(API_DIR)/BaseDerivedData/$(PRODUCTS) -o $(API_DIR)/base.json
	$(API_DUMP) -I $(DERIVED_DATA)/$(PRODUCTS) -o $(API_DIR)/current.json
	@xcrun swift-api-digester -diagnose-sdk -input-paths $(API_DIR)/base.json -input-paths $(API_DIR)/current.json \
		-o $(API_DIR)/breaking-changes.txt 2>/dev/null
	@grep -v -e '^$$' -e '^/\*' $(API_DIR)/breaking-changes.txt || echo "No breaking changes of the public API."

lint:
	swiftlint lint --strict --quiet

clean:
	rm -rf .build
