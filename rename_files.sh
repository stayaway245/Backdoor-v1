#!/bin/bash

# Rename directories
echo "Renaming directories..."
# Core Data model
mv Shared/Data/Feather.xcdatamodeld Shared/Data/Backdoor.xcdatamodeld
mv Shared/Data/Feather.xcdatamodeld/Feather.xcdatamodel Shared/Data/Backdoor.xcdatamodeld/Backdoor.xcdatamodel

# Bridging header
mv "Shared/Magic/feather-Bridging-Header.h" "Shared/Magic/backdoor-Bridging-Header.h"

# Xcode project and workspace
mv feather.xcodeproj backdoor.xcodeproj
mv feather.xcworkspace backdoor.xcworkspace

echo "Renaming complete!"

# Rename image asset directory
echo "Renaming image asset directory..."
if [ -d "iOS/Resources/Assets.xcassets/feather_glyph.imageset" ]; then
    mv "iOS/Resources/Assets.xcassets/feather_glyph.imageset" "iOS/Resources/Assets.xcassets/backdoor_glyph.imageset"
fi
