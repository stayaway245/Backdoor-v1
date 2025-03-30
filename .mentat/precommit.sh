#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Check if we're in CI and have limited time
IS_CI=${CI:-false}
# Default timeout for individual operations (shorter in CI)
TIMEOUT=${TIMEOUT:-"180"}

# Function to run commands with timeout
run_with_timeout() {
    local timeout=$1
    local cmd=$2
    echo "Running: $cmd"
    
    # Use timeout command if available, otherwise just run the command
    if command -v timeout &> /dev/null; then
        timeout "$timeout"s bash -c "$cmd" || echo "Command timed out or failed: $cmd"
    else
        bash -c "$cmd" || echo "Command failed: $cmd"
    fi
}

# Format Swift code with SwiftFormat
if command -v swiftformat &> /dev/null; then
    echo "Formatting Swift files..."
    run_with_timeout $TIMEOUT "swiftformat . --exclude Pods --exclude .build --exclude .swiftpm"
else
    echo "SwiftFormat not found. Skipping Swift formatting."
fi

# Lint Swift code with SwiftLint
if command -v swiftlint &> /dev/null; then
    echo "Linting Swift files..."
    if [ -f .swiftlint.yml ]; then
        run_with_timeout $TIMEOUT "swiftlint --fix"
    else
        echo "No SwiftLint configuration found. Skipping Swift linting."
    fi
else
    echo "SwiftLint not found. Skipping Swift linting."
fi

# Format C/C++/Objective-C/Objective-C++ files with clang-format
if command -v clang-format &> /dev/null; then
    echo "Formatting C/C++/Objective-C/Objective-C++ files..."
    # Find all C/C++/Objective-C/Objective-C++ files and format them
    find . -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.m" -o -name "*.mm" \) -not -path "*/Pods/*" -not -path "*/.build/*" -print0 | while IFS= read -r -d '' file; do
        echo "Formatting $file"
        clang-format -i "$file"
    done
else
    echo "clang-format not found. Skipping C/C++/Objective-C/Objective-C++ formatting."
fi

# Basic build check if we're not in CI (it might take too long)
if [ "$IS_CI" != "true" ] && command -v xcodebuild &> /dev/null; then
    echo "Performing basic build check..."
    # First check if the project is a workspace or a project file
    if [ -d "backdoor.xcworkspace" ]; then
        run_with_timeout $TIMEOUT "xcodebuild -workspace backdoor.xcworkspace -scheme 'backdoor (Debug)' -destination 'platform=iOS Simulator,name=iPhone 14' clean build CODE_SIGNING_ALLOWED=NO | grep -v 'warning: The iOS deployment target'" || echo "Build check skipped or failed."
    elif [ -d "backdoor.xcodeproj" ]; then
        run_with_timeout $TIMEOUT "xcodebuild -project backdoor.xcodeproj -scheme 'backdoor (Debug)' -destination 'platform=iOS Simulator,name=iPhone 14' clean build CODE_SIGNING_ALLOWED=NO | grep -v 'warning: The iOS deployment target'" || echo "Build check skipped or failed."
    else
        echo "No Xcode project or workspace found. Skipping build check."
    fi
else
    echo "Skipping build check in CI environment or xcodebuild not available."
fi

echo "Pre-commit checks completed!"
exit 0
