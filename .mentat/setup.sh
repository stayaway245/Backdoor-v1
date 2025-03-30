#!/bin/bash
set -e

echo "Installing necessary dependencies..."

# Install Homebrew if not installed (standard practice for macOS dependencies)
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
    # The "|| true" is to prevent script failure if running in CI where brew might be unavailable
fi

# Install SwiftLint for linting if available through brew
if command -v brew &> /dev/null; then
    echo "Installing SwiftLint..."
    brew install swiftlint || true
else
    # Direct binary installation as fallback
    echo "Attempting to install SwiftLint from GitHub..."
    LATEST_SWIFTLINT_URL=$(curl -s https://api.github.com/repos/realm/SwiftLint/releases/latest | grep browser_download_url | grep portable | cut -d '"' -f 4)
    if [ ! -z "$LATEST_SWIFTLINT_URL" ]; then
        curl -L "$LATEST_SWIFTLINT_URL" -o swiftlint.zip
        unzip -o swiftlint.zip
        chmod +x swiftlint
        mkdir -p $HOME/.local/bin
        mv swiftlint $HOME/.local/bin/
        rm swiftlint.zip
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# Install SwiftFormat for code formatting
if command -v brew &> /dev/null; then
    echo "Installing SwiftFormat..."
    brew install swiftformat || true
else
    # Direct binary installation as fallback
    echo "Attempting to install SwiftFormat from GitHub..."
    LATEST_SWIFTFORMAT_URL=$(curl -s https://api.github.com/repos/nicklockwood/SwiftFormat/releases/latest | grep browser_download_url | grep swiftformat | head -n 1 | cut -d '"' -f 4)
    if [ ! -z "$LATEST_SWIFTFORMAT_URL" ]; then
        curl -L "$LATEST_SWIFTFORMAT_URL" -o swiftformat.zip
        unzip -o swiftformat.zip
        chmod +x swiftformat
        mkdir -p $HOME/.local/bin
        mv swiftformat $HOME/.local/bin/
        rm swiftformat.zip
    fi
fi

# Install ldid for code signing
if command -v brew &> /dev/null; then
    echo "Installing ldid..."
    brew install ldid || true
fi

# Install clang-format for C++/Objective-C++ files
if command -v brew &> /dev/null; then
    echo "Installing clang-format..."
    brew install clang-format || true
else
    echo "Attempting to install clang-format through apt..."
    apt-get update && apt-get install -y clang-format || true
fi

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

echo "Setting up Swift Package Manager dependencies..."
if [ -f "Package.swift" ]; then
    swift package resolve
elif [ -d "backdoor.xcworkspace" ]; then
    echo "Using Xcode workspace for dependencies..."
    # Check if this is running in a macOS environment with Xcode
    if command -v xcodebuild &> /dev/null; then
        echo "Resolving Swift Package Manager dependencies through Xcode..."
        xcodebuild -resolvePackageDependencies -workspace backdoor.xcworkspace || true
    fi
fi

echo "Setup completed!"
exit 0
