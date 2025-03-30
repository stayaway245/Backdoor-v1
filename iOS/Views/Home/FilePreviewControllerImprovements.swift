import UIKit
import QuickLook

// MARK: - Extensions to enhance file preview capabilities

extension FilePreviewController {
    
    /// Present a share sheet for the current file
    func shareFile() {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Configure popover for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    /// Add sharing button to navigation bar
    func setupShareButton() {
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )
        navigationItem.rightBarButtonItem = shareButton
    }
    
    @objc private func shareButtonTapped() {
        shareFile()
    }
    
    /// Add edit capabilities for supported file types
    func setupEditButton() {
        // Only show edit button for editable file types
        let fileExtension = fileURL.pathExtension.lowercased()
        let editableExtensions = ["txt", "md", "plist", "json", "xml", "html", "css", "js", "swift", "py", "java", "c", "cpp", "h", "m"]
        
        if editableExtensions.contains(fileExtension) {
            let editButton = UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(editButtonTapped)
            )
            
            // If we already have a right button, add this as another one
            if let existingButton = navigationItem.rightBarButtonItem {
                navigationItem.rightBarButtonItems = [existingButton, editButton]
            } else {
                navigationItem.rightBarButtonItem = editButton
            }
        }
    }
    
    @objc private func editButtonTapped() {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        if fileExtension == "plist" {
            let editor = PlistEditorViewController(fileURL: fileURL)
            navigationController?.pushViewController(editor, animated: true)
        } else {
            let editor = TextEditorViewController(fileURL: fileURL)
            navigationController?.pushViewController(editor, animated: true)
        }
    }
    
    /// Enable opening in external apps
    func setupOpenInButton() {
        let openInButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(openInButtonTapped)
        )
        
        // If we already have right buttons, add this as another one
        if let existingButtons = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = existingButtons + [openInButton]
        } else if let existingButton = navigationItem.rightBarButtonItem {
            navigationItem.rightBarButtonItems = [existingButton, openInButton]
        } else {
            navigationItem.rightBarButtonItem = openInButton
        }
    }
    
    @objc private func openInButtonTapped() {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // Filter to only show "Open in" options
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.copyToPasteboard,
            UIActivity.ActivityType.mail,
            UIActivity.ActivityType.message,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.saveToCameraRoll
        ]
        
        // Configure popover for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(activityViewController, animated: true)
    }
}

// MARK: - FilePreviewController improvements
extension FilePreviewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupShareButton()
        setupEditButton()
        setupOpenInButton()
    }
}
