//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

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
    
    // Method to handle opening directory
    func openDirectory(_ file: File) {
        // Navigation logic to open a directory
        let directoryVC = DirectoryViewController(directory: file.url)
        navigationController?.pushViewController(directoryVC, animated: true)
    }
    
    // Method to present archive options
    func presentArchiveOptions(for file: File) {
        let alert = UIAlertController(title: "Archive Options", message: "What would you like to do with this archive?", preferredStyle: .actionSheet)
        
        let extractAction = UIAlertAction(title: "Extract", style: .default) { [weak self] _ in
            self?.extractArchive(file)
        }
        
        let viewAction = UIAlertAction(title: "View Contents", style: .default) { [weak self] _ in
            self?.presentFilePreview(for: file)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(extractAction)
        alert.addAction(viewAction)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    // Method to extract archive
    func extractArchive(_ file: File) {
        // Show extraction options dialog
        let alert = UIAlertController(title: "Extract Archive", message: "Choose destination for extracted files", preferredStyle: .alert)
        
        alert.addTextField { textField in
            // Default to the archive name without extension
            textField.text = file.url.deletingPathExtension().lastPathComponent
            textField.placeholder = "Folder Name"
            textField.autocapitalizationType = .none
        }
        
        let extractAction = UIAlertAction(title: "Extract", style: .default) { [weak self] _ in
            guard let self = self,
                  let folderName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !folderName.isEmpty else { return }
            
            self.fileHandlers.unzipFile(
                viewController: self,
                fileURL: file.url,
                destinationName: folderName
            ) { [weak self] result in
                switch result {
                case .success:
                    let successAlert = UIAlertController(
                        title: "Extraction Complete",
                        message: "Files have been extracted successfully.",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(successAlert, animated: true, completion: nil)
                case .failure(let error):
                    self?.utilities.handleError(in: self!, error: error, withTitle: "Extraction Failed")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(extractAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    /// Open a file based on its type
    func openFile(_ file: File) {
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
    
    // Function to rename a file
    func renameFile(_ file: File) {
        let alert = UIAlertController(title: "Rename File", message: "Enter new name for \(file.name)", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = file.name
            textField.placeholder = "New Name"
            textField.autocapitalizationType = .none
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty,
                  newName != file.name else { return }
            
            let sourceURL = file.url
            let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)
            
            do {
                try self.fileManager.moveItem(at: sourceURL, to: destinationURL)
                self.loadFiles()
                HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            } catch {
                self.utilities.handleError(in: self, error: error, withTitle: "Rename Failed")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(renameAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
