import UIKit
import QuickLook

// MARK: - HomeViewController Extensions for File Preview and Archive Handling

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
        
        // Use QuickLook for preview
        let previewController = FilePreviewController(fileURL: file.url)
        navigationController?.pushViewController(previewController, animated: true)
    }
    
    /// Present an image preview
    /// - Parameter file: The image file to preview
    func presentImagePreview(for file: File) {
        presentFilePreview(for: file)
    }
    
    /// Extract an archive file
    /// - Parameter file: The archive file to extract
    func extractArchive(_ file: File) {
        // Show loading indicator
        activityIndicator.startAnimating()
        
        // Create extraction directory name (remove extension)
        let extractionName = file.url.deletingPathExtension().lastPathComponent
        let extractionDir = file.url.deletingLastPathComponent().appendingPathComponent(extractionName)
        
        // Check if extraction directory already exists
        if FileManager.default.fileExists(atPath: extractionDir.path) {
            // Show alert asking if we should overwrite
            let alert = UIAlertController(
                title: "Directory Exists",
                message: "A directory named '\(extractionName)' already exists. What would you like to do?",
                preferredStyle: .alert
            )
            
            let overwriteAction = UIAlertAction(title: "Overwrite", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.performExtraction(file: file, to: extractionDir, shouldOverwrite: true)
            }
            
            let createNewAction = UIAlertAction(title: "Create New", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Generate a unique name
                var counter = 1
                var newExtractionDir = extractionDir
                
                while FileManager.default.fileExists(atPath: newExtractionDir.path) {
                    newExtractionDir = file.url.deletingLastPathComponent().appendingPathComponent("\(extractionName)_\(counter)")
                    counter += 1
                }
                
                self.performExtraction(file: file, to: newExtractionDir, shouldOverwrite: false)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
            }
            
            alert.addAction(overwriteAction)
            alert.addAction(createNewAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        } else {
            // No existing directory, proceed with extraction
            performExtraction(file: file, to: extractionDir, shouldOverwrite: false)
        }
    }
    
    /// Perform the actual extraction
    /// - Parameters:
    ///   - file: The archive file to extract
    ///   - extractionDir: The directory to extract to
    ///   - shouldOverwrite: Whether to overwrite existing files
    private func performExtraction(file: File, to extractionDir: URL, shouldOverwrite: Bool) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Remove existing directory if overwriting
                if shouldOverwrite && FileManager.default.fileExists(atPath: extractionDir.path) {
                    try FileManager.default.removeItem(at: extractionDir)
                }
                
                // Create extraction directory
                try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true, attributes: nil)
                
                // Extract the archive
                try FileManager.default.unzipItem(at: file.url, to: extractionDir)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.loadFiles()
                    
                    // Show success message
                    let alert = UIAlertController(
                        title: "Extraction Complete",
                        message: "The archive has been extracted to '\(extractionDir.lastPathComponent)'.",
                        preferredStyle: .alert
                    )
                    
                    let openAction = UIAlertAction(title: "Open Folder", style: .default) { [weak self] _ in
                        guard let self = self else { return }
                        
                        // Create a File object for the extraction directory
                        let extractedDirFile = File(url: extractionDir)
                        self.openDirectory(extractedDirFile)
                    }
                    
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    
                    alert.addAction(openAction)
                    alert.addAction(okAction)
                    alert.preferredAction = openAction
                    
                    self.present(alert, animated: true)
                    
                    // Provide haptic feedback
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(
                        in: self,
                        error: error,
                        withTitle: "Extraction Failed"
                    )
                }
            }
        }
    }
}
