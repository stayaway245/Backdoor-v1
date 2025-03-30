import UIKit

extension HomeViewController {
    
    // MARK: - Swipe Actions for TableView
    
    /// Configure swipe actions for a table view row
    /// - Parameters:
    ///   - tableView: The table view
    ///   - indexPath: The index path of the row
    /// - Returns: A swipe actions configuration
    func configureSwipeActionsForRow(at indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            if let index = self.fileList.firstIndex(of: file) {
                self.deleteFile(at: index)
            }
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        // Share action
        let shareAction = UIContextualAction(style: .normal, title: "Share") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let activityViewController = UIActivityViewController(activityItems: [file.url], applicationActivities: nil)
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = tableView.cellForRow(at: indexPath)
            }
            self.present(activityViewController, animated: true, completion: nil)
            completion(true)
        }
        shareAction.backgroundColor = UIColor.systemBlue
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        
        var actions = [deleteAction, shareAction]
        
        // Add file-specific actions
        if !file.isDirectory {
            // Rename action for quick editing
            let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                self.renameFile(file)
                completion(true)
            }
            renameAction.backgroundColor = .systemGreen
            renameAction.image = UIImage(systemName: "pencil")
            actions.append(renameAction)
            
            // Add extract action for archives
            let fileExtension = file.url.pathExtension.lowercased()
            if ["zip", "gz", "tar", "7z", "rar"].contains(fileExtension) {
                let extractAction = UIContextualAction(style: .normal, title: "Extract") { [weak self] (_, _, completion) in
                    guard let self = self else { return }
                    self.extractArchive(file)
                    completion(true)
                }
                extractAction.backgroundColor = .systemOrange
                extractAction.image = UIImage(systemName: "archivebox")
                actions.append(extractAction)
            }
        } else {
            // Compress action for directories
            let compressAction = UIContextualAction(style: .normal, title: "Compress") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                self.compressDirectory(file)
                completion(true)
            }
            compressAction.backgroundColor = .systemOrange
            compressAction.image = UIImage(systemName: "archivebox")
            actions.append(compressAction)
        }
        
        // Configure the swipe actions
        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    /// Compress a directory into a ZIP file
    /// - Parameter directory: The directory to compress
    func compressDirectory(_ directory: File) {
        guard directory.isDirectory else { return }
        
        // Create the output ZIP filename
        let zipFileName = directory.name + ".zip"
        let zipURL = directory.url.deletingLastPathComponent().appendingPathComponent(zipFileName)
        
        // Show activity indicator
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Check if a file with this name already exists
                if self.fileManager.fileExists(atPath: zipURL.path) {
                    try self.fileManager.removeItem(at: zipURL)
                }
                
                // Compress the directory
                try self.fileManager.zipItem(at: directory.url, to: zipURL)
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadFiles()
                    
                    // Notify user of success
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                    
                    let alert = UIAlertController(
                        title: "Compression Complete",
                        message: "Directory '\(directory.name)' has been compressed to '\(zipFileName)'",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(
                        in: self,
                        error: error,
                        withTitle: "Compression Error"
                    )
                }
            }
        }
    }
}
