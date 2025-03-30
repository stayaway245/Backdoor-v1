TARGET_CODESIGN = $(shell which ldid)

PLATFORM = iphoneos
NAME = backdoor
SCHEME ?= 'backdoor (Release)'
RELEASE = Release-iphoneos
CONFIGURATION = Release

MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk $(PLATFORM) --show-sdk-path)

APP_TMP         = $(TMPDIR)/$(NAME)
STAGE_DIR   = $(APP_TMP)/stage
APP_DIR     = $(APP_TMP)/Build/Products/$(RELEASE)/$(NAME).app

# Default CFLAGS if not provided externally
CFLAGS ?= -O

all: package

# Resolve dependencies with SPM before building
dependencies:
	@echo "Resolving Swift Package Manager dependencies..."
	@swift package resolve

# Build the project
build: dependencies
	@echo "Building $(NAME) with scheme $(SCHEME) in $(CONFIGURATION) configuration..."
	@rm -rf $(APP_TMP)
	
	@set -o pipefail; \
		xcodebuild \
		-jobs $(shell sysctl -n hw.ncpu) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-arch arm64 -sdk $(PLATFORM) \
		-derivedDataPath $(APP_TMP) \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGN_IDENTITY="-" \
		DSTROOT=$(APP_TMP)/install \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
		SUPPORTS_MACCATALYST=NO \
		SWIFT_OPTIMIZATION_LEVEL="-O" \
		OTHER_SWIFT_FLAGS="-cross-module-optimization" \
		GCC_OPTIMIZATION_LEVEL=3 \
		SWIFT_COMPILATION_MODE=wholemodule \
		CFLAGS="$(CFLAGS)"

# Package the built app into an IPA
package: build
	@echo "Packaging $(NAME) into IPA..."
	@rm -rf Payload
	@rm -rf $(STAGE_DIR)/
	@mkdir -p $(STAGE_DIR)/Payload
	@mv $(APP_DIR) $(STAGE_DIR)/Payload/$(NAME).app
	
	@echo "Removing code signature..."
	@rm -rf $(STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	
	@echo "Signing with ldid..."
	@$(TARGET_CODESIGN) -S $(STAGE_DIR)/Payload/$(NAME).app
	
	@ln -sf $(STAGE_DIR)/Payload Payload
	@rm -rf packages
	@mkdir -p packages

ifeq ($(TIPA),1)
	@echo "Creating TIPA package..."
	@zip -r9 packages/$(NAME)-ts.tipa Payload
else
	@echo "Creating IPA package..."
	@zip -r9 packages/$(NAME).ipa Payload
endif
	@echo "Build completed: packages/$(NAME).ipa"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf apple-include
	@rm -rf $(APP_TMP)

.PHONY: all dependencies build package clean