#!/bin/bash
set -e

echo "Installing necessary dependencies..."

# Function to install SwiftLint
install_swiftlint() {
    echo "Installing SwiftLint..."
    
    # Check if SwiftLint is already available
    if command -v swiftlint &> /dev/null; then
        echo "SwiftLint already installed"
        return
    fi
    
    # Try to download pre-built binary
    echo "Downloading SwiftLint..."
    LATEST_SWIFTLINT_URL=$(curl -s https://api.github.com/repos/realm/SwiftLint/releases/latest | grep browser_download_url | grep portable | cut -d '"' -f 4)
    
    if [ ! -z "$LATEST_SWIFTLINT_URL" ]; then
        curl -L "$LATEST_SWIFTLINT_URL" -o swiftlint.zip
        unzip -o swiftlint.zip
        if [ -f "swiftlint" ]; then
            chmod +x swiftlint
            mkdir -p $HOME/.local/bin
            mv swiftlint $HOME/.local/bin/
            rm -f swiftlint.zip LICENSE
            export PATH="$HOME/.local/bin:$PATH"
            echo "SwiftLint installed successfully"
        else
            echo "Error: SwiftLint binary not found in the downloaded package"
        fi
    else
        echo "Error: Could not find SwiftLint download URL"
    fi
}

# Function to install SwiftFormat
install_swiftformat() {
    echo "Installing SwiftFormat..."
    
    # Check if SwiftFormat is already available
    if command -v swiftformat &> /dev/null; then
        echo "SwiftFormat already installed"
        return
    fi
    
    # Download the latest release
    echo "Downloading SwiftFormat..."
    # First try direct binary download
    LATEST_SWIFTFORMAT_URL=$(curl -s https://api.github.com/repos/nicklockwood/SwiftFormat/releases/latest | \
        grep browser_download_url | \
        grep -v artifactbundle | \
        grep -v .zip | \
        grep -E "swiftformat$" | \
        head -n 1 | \
        cut -d '"' -f 4)
    
    if [ ! -z "$LATEST_SWIFTFORMAT_URL" ]; then
        echo "Found direct SwiftFormat binary at $LATEST_SWIFTFORMAT_URL"
        curl -L "$LATEST_SWIFTFORMAT_URL" -o swiftformat
        chmod +x swiftformat
        mkdir -p $HOME/.local/bin
        mv swiftformat $HOME/.local/bin/
        export PATH="$HOME/.local/bin:$PATH"
        echo "SwiftFormat installed successfully"
    else
        # Try artifact bundle as fallback
        echo "No direct binary found, trying artifact bundle..."
        BUNDLE_URL=$(curl -s https://api.github.com/repos/nicklockwood/SwiftFormat/releases/latest | \
            grep browser_download_url | \
            grep artifactbundle | \
            head -n 1 | \
            cut -d '"' -f 4)
        
        if [ ! -z "$BUNDLE_URL" ]; then
            echo "Found SwiftFormat artifact bundle at $BUNDLE_URL"
            TEMP_DIR=$(mktemp -d)
            curl -L "$BUNDLE_URL" -o "$TEMP_DIR/swiftformat.zip"
            unzip -o "$TEMP_DIR/swiftformat.zip" -d "$TEMP_DIR"
            
            # Try to find the correct binary for this platform
            if [[ "$(uname)" == "Darwin" ]]; then
                # macOS
                SWIFTFORMAT_BIN=$(find "$TEMP_DIR" -name "swiftformat" -type f | grep -v linux | head -n 1)
            else
                # Linux - try to match architecture
                if [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
                    SWIFTFORMAT_BIN=$(find "$TEMP_DIR" -name "*aarch64*" -type f | head -n 1)
                else
                    SWIFTFORMAT_BIN=$(find "$TEMP_DIR" -name "*linux*" -type f | grep -v aarch64 | head -n 1)
                fi
            fi
            
            if [ ! -z "$SWIFTFORMAT_BIN" ]; then
                echo "Found binary at $SWIFTFORMAT_BIN"
                chmod +x "$SWIFTFORMAT_BIN"
                mkdir -p $HOME/.local/bin
                cp "$SWIFTFORMAT_BIN" "$HOME/.local/bin/swiftformat"
                export PATH="$HOME/.local/bin:$PATH"
                echo "SwiftFormat installed successfully"
            else
                echo "Error: Could not find SwiftFormat binary in artifact bundle"
            fi
            
            rm -rf "$TEMP_DIR"
        else
            echo "Error: Could not find SwiftFormat download URL"
        fi
    fi
}

# Function to install clang-format
install_clang_format() {
    echo "Installing clang-format..."
    
    # Check if clang-format is already available
    if command -v clang-format &> /dev/null; then
        echo "clang-format already installed"
        return
    fi
    
    # Try apt-get for Debian-based systems
    if command -v apt-get &> /dev/null; then
        echo "Trying to install clang-format via apt-get..."
        apt-get update -y
        apt-get install -y clang-format || echo "Failed to install clang-format via apt-get"
        return
    fi
    
    # Try yum for Red Hat-based systems
    if command -v yum &> /dev/null; then
        echo "Trying to install clang-format via yum..."
        yum install -y clang-tools-extra || echo "Failed to install clang-format via yum"
        return
    fi
    
    echo "Could not install clang-format automatically. Please install it manually."
}

# Install the tools
install_swiftlint
install_swiftformat
install_clang_format

# Initialize SwiftLint configuration if not exists
if ! [ -f .swiftlint.yml ]; then
    echo "Creating default SwiftLint configuration..."
    cat > .swiftlint.yml << 'SWIFTLINT_CONFIG'
disabled_rules:
  - trailing_whitespace
  - line_length
  - cyclomatic_complexity
  - function_body_length
  - file_length
  - force_cast
  - type_body_length

included:
  - iOS
  - Shared

excluded:
  - Pods
  - .build
  - .swiftpm
SWIFTLINT_CONFIG
fi

# Initialize SwiftFormat configuration if not exists
if ! [ -f .swiftformat ]; then
    echo "Creating default SwiftFormat configuration..."
    cat > .swiftformat << 'SWIFTFORMAT_CONFIG'
--indent 4
--indentcase true
--trimwhitespace always
--importgrouping alphabetized
--semicolons never
--header strip
--disable redundantSelf
SWIFTFORMAT_CONFIG
fi

# Initialize .clang-format for C++/Objective-C files
if ! [ -f .clang-format ]; then
    echo "Creating default .clang-format configuration..."
    cat > .clang-format << 'CLANG_FORMAT_CONFIG'
BasedOnStyle: LLVM
IndentWidth: 4
TabWidth: 4
UseTab: Never
ColumnLimit: 120
AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false
IndentCaseLabels: true
AccessModifierOffset: -4
CLANG_FORMAT_CONFIG
fi

# Add the local bin directory to PATH in the current shell session
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    echo "Added $HOME/.local/bin to PATH"
fi

# Resolve Swift Package Manager dependencies if possible
echo "Setting up Swift Package Manager dependencies if available..."
if [ -f "Package.swift" ]; then
    if command -v swift &> /dev/null; then
        swift package resolve || echo "Failed to resolve Swift packages"
    else
        echo "Swift not available. Dependencies will be resolved by Xcode."
    fi
elif [ -d "backdoor.xcworkspace" ]; then
    echo "Using Xcode workspace for dependencies (will be resolved by Xcode)."
    # Only try this if xcodebuild is available (MacOS)
    if command -v xcodebuild &> /dev/null; then
        xcodebuild -resolvePackageDependencies -workspace backdoor.xcworkspace || \
        echo "Failed to resolve dependencies via Xcode. This may be expected in CI environments."
    fi
fi

echo "Setup completed!"
exit 0
