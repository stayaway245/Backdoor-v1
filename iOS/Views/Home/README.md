# File Management System

This comprehensive file management system provides a complete solution for handling various file types, navigating directories, and performing common file operations. It integrates seamlessly with the Backdoor app and enhances the user experience with intuitive interactions.

## Features

### File Navigation
- Single-click to open files and folders
- Long-press for context menu options
- Swipe actions for quick operations (delete, share, rename)
- Hierarchical directory navigation

### File Type Support
- Text files: .txt, .md, .rtf, etc.
- Documents: .pdf, .doc, .docx, .xls, .xlsx, etc.
- Images: .jpg, .png, .gif, .heic, etc.
- Video: .mp4, .mov, .3gp, etc.
- Audio: .mp3, .m4a, .wav, etc.
- Archives: .zip, .rar, .tar, .7z, etc.
- Special: .ipa files with signing support

### File Operations
- View and edit text files
- Preview images, documents, and media
- Extract and compress archives
- Sign IPA files
- Share files with other apps
- Create new files and folders
- Take photos directly into the file system

### UI Enhancements
- Intuitive context menus
- Rich swipe actions
- File type-specific icons
- QuickLook integration for file previews
- Smooth navigation between directories

## Implementation Details

The system consists of several key components:

1. **DirectoryViewController**: Extends HomeViewController for proper directory navigation
2. **FileContextMenu**: Implements context menu actions for different file types
3. **FilePreviewController**: Provides QuickLook integration for file previews
4. **Enhanced HomeViewController**: Supports more file types and operations

## Usage

The file management system works out of the box with the following interactions:

1. **Opening Files**
   - Tap on a file to open it in the appropriate viewer/editor
   - Tap on a folder to navigate into it

2. **Context Menu**
   - Long-press on any file or folder to show context menu options
   - Options include Open, Share, Rename, Delete, and more

3. **Swipe Actions**
   - Swipe left on a file to reveal quick actions
   - Actions vary based on file type (delete, share, rename, extract)

4. **File Creation**
   - Use the + button to create new files or folders
   - Create text files and take photos directly

## Future Enhancements

Possible future enhancements include:

1. Text file syntax highlighting
2. File search with content indexing
3. File tagging and categorization
4. Cloud storage integration
5. Batch operations for multiple files

## Notes

- File size limitations are in place for very large files
- Enhanced preview capabilities require iOS 13+
- Some file operations may require appropriate permissions
