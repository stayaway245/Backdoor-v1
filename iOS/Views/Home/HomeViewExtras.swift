import UIKit

// Extension to add extra methods needed by the HomeViewController
extension HomeViewController {
    
    // MARK: - File Creation Methods
    
    /// Creates a new file in the specified directory
    /// - Parameter directory: The directory to create the file in
    func createNewFile(in directory: File) {
        guard directory.isDirectory else { return }
        
        let alert = UIAlertController(title: "Create New File", message: "Enter a name for the new file", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "File Name"
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let fileName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !fileName.isEmpty else { return }
            
            let fileURL = directory.url.appendingPathComponent(fileName)
            
            // Create empty file
            self.fileHandlers.createNewFile(viewController: self, fileName: fileURL.path) { result in
                switch result {
                case .success:
                    self.loadFiles()
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                case .failure(let error):
                    self.utilities.handleError(in: self, error: error, withTitle: "File Creation Error")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    /// Creates a new folder in the specified directory
    /// - Parameter directory: The directory to create the folder in
    func createNewFolder(in directory: File) {
        guard directory.isDirectory else { return }
        
        let alert = UIAlertController(title: "Create New Folder", message: "Enter a name for the new folder", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Folder Name"
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let folderName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !folderName.isEmpty else { return }
            
            let folderURL = directory.url.appendingPathComponent(folderName)
            
            self.fileHandlers.createNewFolder(viewController: self, folderName: folderURL.path) { result in
                switch result {
                case .success:
                    self.loadFiles()
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                case .failure(let error):
                    self.utilities.handleError(in: self, error: error, withTitle: "Folder Creation Error")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - UIKit Extensions for UI Effects
    
    /// Applies a futuristic transition effect to the view
    func applyFuturisticTransition() {
        // Create a snapshot of the current view
        guard let snapshot = view.snapshotView(afterScreenUpdates: false) else { return }
        view.addSubview(snapshot)
        
        // Apply a scale and fade animation
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            snapshot.alpha = 0
            snapshot.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { _ in
            snapshot.removeFromSuperview()
        })
    }
}

// Extension to add layer effects
extension CALayer {
    func applyFuturisticShadow() {
        shadowColor = UIColor.black.cgColor
        shadowOffset = CGSize(width: 0, height: 2)
        shadowOpacity = 0.2
        shadowRadius = 5
        masksToBounds = false
    }
}
