# Update Localization Strings

This PR updates the localization strings in the application to support all UI elements and provide better user experience across all supported languages.

## Changes Made

1. **Fixed Duplicate Key**:
   - Changed `APPS_INFORMATION_SECTION_TITLE_NAME` (duplicate) to `APPS_INFORMATION_SECTION_TITLE_BUNDLE` 

2. **Added New Generic UI Actions**:
   - Added `SHARE`, `OPEN`, `CREATE`, `FIND_REPLACE`, etc.
   - Added sort-related strings (`SORT_BY`, `SORT_BY_NAME`, etc.)

3. **Added New Error and Success Messages**:
   - Added file operation related error messages
   - Added success messages for file operations

4. **Added Home Tab Support**:
   - Added `TAB_HOME` for the Home tab
   - Added Home section strings for file management UI

5. **Added File Editor Strings**:
   - Added strings for various editor types (hex, text, plist, IPA)

6. **Added AI Assistant Strings**:
   - Added strings for the chat interface
   - Added error and status messages for the AI Assistant

## Benefits

These changes ensure that:
- All UI elements have proper localization support
- User-facing error and success messages can be translated
- New features (Home, AI Assistant) are properly localized
- Developers can easily add translations for these strings in other languages

## Tests

Tested that all keys are correctly formatted and follow the existing patterns.
