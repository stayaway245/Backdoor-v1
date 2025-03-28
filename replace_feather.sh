#!/bin/bash

# Function to replace standalone words only
replace_standalone() {
    local file="$1"
    local from_word="$2"
    local to_word="$3"
    
    # Skip binary files
    if file "$file" | grep -q "binary"; then
        echo "Skipping binary file: $file"
        return
    fi
    
    # Use grep to check if the file contains the word and only perform replacement if it does
    if grep -q "\<$from_word\>" "$file"; then
        echo "Replacing in $file: $from_word -> $to_word"
        # Use sed with word boundaries to replace only standalone occurrences
        sed -i "s/\<$from_word\>/$to_word/g" "$file"
    fi
}

# Start with Swift files
echo "Processing Swift files..."
find . -name "*.swift" | while read file; do
    replace_standalone "$file" "feather" "backdoor"
    replace_standalone "$file" "Feather" "Backdoor"
done

# Process Info.plist files
echo "Processing plist files..."
find . -name "*.plist" | while read file; do
    replace_standalone "$file" "feather" "backdoor"
    replace_standalone "$file" "Feather" "Backdoor"
    # Replace bundle IDs
    sed -i 's/kh\.crysalis\.feather/kh.crysalis.backdoor/g' "$file"
done

# Process project configuration files
echo "Processing project files..."
find . -name "*.pbxproj" | while read file; do
    replace_standalone "$file" "feather" "backdoor"
    replace_standalone "$file" "Feather" "Backdoor"
    # Replace bundle IDs
    sed -i 's/kh\.crysalis\.feather/kh.crysalis.backdoor/g' "$file"
    # Replace bridging header path
    sed -i 's/Shared\/Magic\/feather-Bridging-Header.h/Shared\/Magic\/backdoor-Bridging-Header.h/g' "$file"
done

# Process Markdown files
echo "Processing markdown files..."
find . -name "*.md" | while read file; do
    replace_standalone "$file" "feather" "backdoor"
    replace_standalone "$file" "Feather" "Backdoor"
done

# Process Objective-C files
echo "Processing Objective-C files..."
find . -name "*.h" -o -name "*.m" -o -name "*.mm" | while read file; do
    replace_standalone "$file" "feather" "backdoor"
    replace_standalone "$file" "Feather" "Backdoor"
done

# Replace GitHub URLs
echo "Updating GitHub URLs..."
find . -name "*.swift" -o -name "*.md" -o -name "*.plist" | while read file; do
    sed -i 's/github.com\/khcrysalis\/feather/github.com\/khcrysalis\/backdoor/g' "$file"
    sed -i 's/github.com\/khcrysalis\/Feather/github.com\/khcrysalis\/Backdoor/g' "$file"
    sed -i 's/githubusercontent.com\/khcrysalis\/.*\/feather\//githubusercontent.com\/khcrysalis\/project-credits\/refs\/heads\/main\/backdoor\//g' "$file"
done

# Replace preference keys
echo "Updating preference keys..."
find . -name "*.swift" | while read file; do
    sed -i 's/\(key: \)"Feather\./\1"Backdoor\./g' "$file"
    sed -i 's/@Storage(key: "Feather\./@Storage(key: "Backdoor\./g' "$file"
    sed -i 's/@CodableStorage(key: "Feather\./@CodableStorage(key: "Backdoor\./g' "$file"
done

echo "Replacement complete!"

# Handle renaming of image assets - more specific than the general replacements
echo "Updating image references..."
find . -name "*.swift" -o -name "*.storyboard" -o -name "*.xib" | while read file; do
    # Skip binary files
    if file "$file" | grep -q "binary"; then
        continue
    fi
    
    # Replace feather_glyph image references
    if grep -q "feather_glyph" "$file"; then
        echo "Replacing image reference in $file"
        sed -i 's/feather_glyph/backdoor_glyph/g' "$file"
    fi
done
