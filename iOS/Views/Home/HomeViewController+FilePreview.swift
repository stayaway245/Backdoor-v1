import UIKit
import QuickLook

extension HomeViewController {
    /// Present a preview for a file
    /// - Parameter file: The file to preview
    func presentFilePreview(for file: File) {
        // Check if the file exists
        guard FileManager.default.fileExists(atPath: file.url.path) else {
            utilities.handleError(
                in: self,
                error: FileAppError.fileNotFound(file.name),
                withTitle: "File Not Found"
            )
            return
        }
        
        // Use the preview controller
        let previewController = FilePreviewController(fileURL: file.url)
        navigationController?.pushViewController(previewController, animated: true)
    }
    
    /// Present an image preview
    /// - Parameter file: The image file to preview
    func presentImagePreview(for file: File) {
        presentFilePreview(for: file)
    }
    
    /// Enhance the openFile method to handle more file types
    func openFileWithExtraSupport(_ file: File) {
        // Most common file type extensions
        let textFileExtensions = ["txt", "md", "swift", "h", "m", "c", "cpp", "js", "html", "css", "json", "strings", "py", "java", "xml", "csv"]
        let imageFileExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp", "svg"]
        let videoFileExtensions = ["mp4", "mov", "m4v", "3gp", "avi", "flv", "mpg", "wmv", "mkv"]
        let audioFileExtensions = ["mp3", "m4a", "wav", "aac", "flac", "ogg"]
        let documentFileExtensions = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key"]
        let archiveFileExtensions = ["zip", "gz", "tar", "7z", "rar", "bz2", "dmg"]
        
        // Get file extension
        let fileExtension = file.url.pathExtension.lowercased()
        
        // Process based on file type
        if file.isDirectory {
            openDirectory(file)
        } else if textFileExtensions.contains(fileExtension) {
            // Special case for plist files
            if fileExtension == "plist" || fileExtension == "entitlements" {
                let editor = PlistEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
            } else {
                let editor = TextEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
            }
        } else if imageFileExtensions.contains(fileExtension) {
            presentImagePreview(for: file)
        } else if videoFileExtensions.contains(fileExtension) || audioFileExtensions.contains(fileExtension) || documentFileExtensions.contains(fileExtension) {
            presentFilePreview(for: file)
        } else if archiveFileExtensions.contains(fileExtension) {
            presentArchiveOptions(for: file)
        } else if fileExtension == "ipa" {
            let editor = IPAEditorViewController(fileURL: file.url)
            navigationController?.pushViewController(editor, animated: true)
        } else {
            // For all other files, check if QuickLook can preview it
            if QLPreviewController.canPreview(file.url as QLPreviewItem) {
                presentFilePreview(for: file)
            } else {
                // Fall back to hex editor for binary files
                let editor = HexEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
            }
        }
    }
}
