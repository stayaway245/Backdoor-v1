import UIKit
import QuickLook

class FilePreviewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    // MARK: - Properties
    
    /// The file URL to preview
    private let fileURL: URL
    
    /// The preview controller
    private let previewController = QLPreviewController()
    
    // MARK: - Initialization
    
    /// Initialize with a file URL
    /// - Parameter fileURL: The URL of the file to preview
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
        title = fileURL.lastPathComponent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewController()
    }
    
    // MARK: - Setup
    
    /// Sets up the preview controller
    private func setupPreviewController() {
        previewController.dataSource = self
        previewController.delegate = self
        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.view.frame = view.bounds
        previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewController.didMove(toParent: self)
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    
    func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
        // Handle any updates if needed
    }
}
