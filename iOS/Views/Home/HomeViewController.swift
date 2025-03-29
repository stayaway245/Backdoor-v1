import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UISearchResultsUpdating, UIDocumentPickerDelegate, FileHandlingDelegate, UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate {
    
    // MARK: - Properties
    var fileList: [File] = []
    private var filteredFileList: [File] = []
    private let fileManager = FileManager.default
    private let searchController = UISearchController(searchResultsController: nil)
    private var sortOrder: SortOrder = .name
    private let fileHandlers = HomeViewFileHandlers()
    private let utilities = HomeViewUtilities()
    private let tableHandlers = HomeViewTableHandlers(utilities: HomeViewUtilities()) // Initialize with utilities
    
    /// The base directory for storing files
    /// Uses the app's documents directory with a "files" subdirectory
    var documentsDirectory: URL {
        get {
            // Get the documents directory safely
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                // This is a serious error - log it and return a fallback directory
                Debug.shared.log(message: "Failed to get documents directory, using temporary directory as fallback", type: .error)
                return FileManager.default.temporaryDirectory.appendingPathComponent("files")
            }
            
            // Create the files subdirectory
            let directory = documentsURL.appendingPathComponent("files")
            createFilesDirectoryIfNeeded(at: directory)
            return directory
        }
    }
    
    enum SortOrder: String {
        case name, date, size
    }
    
    var activityIndicator: UIActivityIndicatorView {
        return HomeViewUI.activityIndicator
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
        loadFiles()
        configureTableView()
    }
    
    deinit {
        // No observation to invalidate
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        view.layer.applyFuturisticShadow()
        
        let navItem = UINavigationItem(title: "File Nexus")
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle.fill"), style: .plain, target: self, action: #selector(showMenu))
        let uploadButton = UIBarButtonItem(customView: HomeViewUI.uploadButton)
        let addButton = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addDirectory))
        
        HomeViewUI.uploadButton.addTarget(self, action: #selector(importFile), for: .touchUpInside)
        HomeViewUI.uploadButton.addGradientBackground()
        navItem.rightBarButtonItems = [menuButton, uploadButton, addButton]
        HomeViewUI.navigationBar.setItems([navItem], animated: false)
        view.addSubview(HomeViewUI.navigationBar)
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        searchController.searchBar.tintColor = .systemCyan
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        view.addSubview(HomeViewUI.fileListTableView)
        NSLayoutConstraint.activate([
            HomeViewUI.navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            HomeViewUI.navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            HomeViewUI.navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            HomeViewUI.fileListTableView.topAnchor.constraint(equalTo: HomeViewUI.navigationBar.bottomAnchor, constant: 10),
            HomeViewUI.fileListTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            HomeViewUI.fileListTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            HomeViewUI.fileListTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        applyFuturisticTransition()
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func configureTableView() {
        HomeViewUI.fileListTableView.delegate = self
        HomeViewUI.fileListTableView.dataSource = self
        HomeViewUI.fileListTableView.dragDelegate = self
        HomeViewUI.fileListTableView.dropDelegate = self
        HomeViewUI.fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
        HomeViewUI.fileListTableView.backgroundColor = .clear
        HomeViewUI.fileListTableView.layer.cornerRadius = 15
        HomeViewUI.fileListTableView.layer.applyFuturisticShadow()
    }
    
    /// Creates the files directory if it doesn't exist
    /// - Parameter directory: The directory URL to create
    /// - Returns: True if the directory exists or was created successfully, false otherwise
    @discardableResult
    private func createFilesDirectoryIfNeeded(at directory: URL) -> Bool {
        // Check if directory already exists
        if fileManager.fileExists(atPath: directory.path) {
            return true
        }
        
        // Directory doesn't exist, try to create it
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            Debug.shared.log(message: "Created directory: \(directory.path)", type: .info)
            return true
        } catch {
            // Log the error and show to user
            Debug.shared.log(message: "Failed to create directory: \(error.localizedDescription)", type: .error)
            utilities.handleError(in: self, error: error, withTitle: "Directory Creation Error")
            return false
        }
    }
    
    private func saveState() {
        UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder")
    }
    
    // MARK: - File Operations
    
    /// Loads files from the documents directory and updates the UI
    func loadFiles() {
        // Start loading indicator
        activityIndicator.startAnimating()
        
        // Ensure the documents directory exists before trying to load files
        if !createFilesDirectoryIfNeeded(at: documentsDirectory) {
            // If we can't create the directory, stop loading
            activityIndicator.stopAnimating()
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Capture the start time for performance measurement
            let startTime = Date()
            
            do {
                // Load directory contents with necessary file attributes
                let fileURLs = try self.fileManager.contentsOfDirectory(
                    at: self.documentsDirectory,
                    includingPropertiesForKeys: [
                        .creationDateKey,
                        .contentModificationDateKey,
                        .fileSizeKey,
                        .isDirectoryKey
                    ],
                    options: .skipsHiddenFiles
                )
                
                // Create File objects with cached attributes for better performance
                // This avoids accessing the filesystem repeatedly when displaying files
                var fileObjects: [File] = []
                for fileURL in fileURLs {
                    let file = File(url: fileURL)
                    fileObjects.append(file)
                }
                
                // Calculate loading time for performance monitoring
                let loadTime = Date().timeIntervalSince(startTime)
                Debug.shared.log(message: "Loaded \(fileObjects.count) files in \(String(format: "%.3f", loadTime))s", type: .info)
                
                // Update UI on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.fileList = fileObjects
                    self.sortFiles()
                    HomeViewUI.fileListTableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    
                    // If no files, show a helpful message
                    if fileObjects.isEmpty {
                        self.showEmptyStateMessage()
                    } else {
                        self.hideEmptyStateMessage()
                    }
                }
            } catch {
                Debug.shared.log(message: "Failed to load files: \(error.localizedDescription)", type: .error)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: self, error: error, withTitle: "File Load Error")
                    
                    // Show empty state with error
                    self.showEmptyStateMessage(withError: error)
                }
            }
        }
    }
    
    /// Shows a message when the file list is empty
    /// - Parameter error: Optional error to show
    private func showEmptyStateMessage(withError error: Error? = nil) {
        // Check if we already have an empty state label
        if let existingLabel = view.viewWithTag(1001) as? UILabel {
            existingLabel.isHidden = false
            
            if let error = error {
                existingLabel.text = "Could not load files.\n\(error.localizedDescription)\n\nTap the upload button to add files."
            } else {
                existingLabel.text = "No files found.\n\nTap the upload button to add files."
            }
            return
        }
        
        // Create a new empty state label
        let emptyLabel = UILabel()
        emptyLabel.tag = 1001
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 16)
        
        if let error = error {
            emptyLabel.text = "Could not load files.\n\(error.localizedDescription)\n\nTap the upload button to add files."
        } else {
            emptyLabel.text = "No files found.\n\nTap the upload button to add files."
        }
        
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: HomeViewUI.fileListTableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: HomeViewUI.fileListTableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: HomeViewUI.fileListTableView.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: HomeViewUI.fileListTableView.trailingAnchor, constant: -40)
        ])
    }
    
    /// Hides the empty state message
    private func hideEmptyStateMessage() {
        if let emptyLabel = view.viewWithTag(1001) {
            emptyLabel.isHidden = true
        }
    }
    
    /// Initiates the file import process
    @objc private func importFile() {
        fileHandlers.uploadFile(viewController: self)
    }
    
    /// Handles a file that has been imported from outside the app
    /// - Parameter url: The URL of the imported file
    func handleImportedFile(url: URL) {
        // Show loading indicator
        activityIndicator.startAnimating()
        
        // Generate a unique name if a file with the same name exists
        let fileName = getUniqueFileName(for: url.lastPathComponent)
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        Debug.shared.log(message: "Importing file from \(url.path) to \(destinationURL.path)", type: .info)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Flag to track if we need to access security-scoped resource
            let needsSecurityScopedAccess = url.startAccessingSecurityScopedResource()
            
            // Make sure we release the security-scoped resource when done
            defer {
                if needsSecurityScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                    Debug.shared.log(message: "Stopped accessing security scoped resource", type: .debug)
                }
            }
            
            do {
                // Validate source file exists and is accessible
                guard self.fileManager.fileExists(atPath: url.path) else {
                    throw FileAppError.fileNotFound(url.lastPathComponent)
                }
                
                // Make sure documents directory exists
                if !self.fileManager.fileExists(atPath: self.documentsDirectory.path) {
                    try self.fileManager.createDirectory(at: self.documentsDirectory, withIntermediateDirectories: true, attributes: nil)
                }
                
                // Ensure we can write to the destination
                guard self.fileManager.isWritableFile(atPath: self.documentsDirectory.path) else {
                    throw FileAppError.permissionDenied("Cannot write to destination directory")
                }
                
                // Handle ZIP files specially - extract their contents
                if url.pathExtension.lowercased() == "zip" {
                    Debug.shared.log(message: "Extracting ZIP file", type: .info)
                    
                    // Create a unique extraction directory
                    let extractionDir = self.documentsDirectory
                    
                    // Extract the ZIP file
                    try self.fileManager.unzipItem(at: url, to: extractionDir)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Show success message
                        let alert = UIAlertController(
                            title: "ZIP Extracted",
                            message: "The ZIP file has been extracted to your files.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    // For non-ZIP files, copy the file to destination
                    Debug.shared.log(message: "Copying file", type: .info)
                    
                    // Check if destination already exists and delete if necessary
                    if self.fileManager.fileExists(atPath: destinationURL.path) {
                        try self.fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Copy the file
                    try self.fileManager.copyItem(at: url, to: destinationURL)
                    
                    // Verify file was copied correctly
                    guard self.fileManager.fileExists(atPath: destinationURL.path) else {
                        throw FileAppError.fileCreationFailed(fileName)
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Show success message
                        let alert = UIAlertController(
                            title: "File Imported",
                            message: "The file has been successfully imported.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } catch {
                Debug.shared.log(message: "Import error: \(error.localizedDescription)", type: .error)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(
                        in: self,
                        error: error,
                        withTitle: "File Import Error"
                    )
                }
            }
        }
    }
    
    /// Generates a unique filename if the original already exists
    /// - Parameter filename: The original filename
    /// - Returns: A unique filename
    private func getUniqueFileName(for filename: String) -> String {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        // If the file doesn't exist, return the original name
        if !fileManager.fileExists(atPath: fileURL.path) {
            return filename
        }
        
        // Split the name and extension
        let fileExtension = fileURL.pathExtension
        let baseName = filename.replacingOccurrences(
            of: ".\(fileExtension)$",
            with: "",
            options: .regularExpression
        )
        
        // Try adding numbers until we find a unique name
        var counter = 1
        var newName: String
        var newURL: URL
        
        repeat {
            if fileExtension.isEmpty {
                newName = "\(baseName) (\(counter))"
            } else {
                newName = "\(baseName) (\(counter)).\(fileExtension)"
            }
            newURL = documentsDirectory.appendingPathComponent(newName)
            counter += 1
        } while fileManager.fileExists(atPath: newURL.path)
        
        return newName
    }
    
    /// Deletes a file at the specified index
    /// - Parameter index: The index of the file to delete
    func deleteFile(at index: Int) {
        // Get the file based on whether we're in search mode or not
        let file = searchController.isActive ? filteredFileList[index] : fileList[index]
        // File URL will be accessed via file.url when needed
        
        // Confirm deletion to prevent accidental data loss
        let fileType = file.isDirectory ? "folder" : "file"
        let message = "Are you sure you want to delete this \(fileType)?\n\nName: \(file.name)\n\(file.formattedSize())"
        
        let alert = UIAlertController(
            title: "Confirm Deletion",
            message: message,
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performFileDeletion(file: file, at: index)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    /// Performs the actual deletion operation after confirmation
    /// - Parameters:
    ///   - file: The file to delete
    ///   - index: The index of the file
    private func performFileDeletion(file: File, at index: Int) {
        activityIndicator.startAnimating()
        
        Debug.shared.log(message: "Deleting file: \(file.url.path)", type: .info)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Check if the file still exists before attempting deletion
                if !self.fileManager.fileExists(atPath: file.url.path) {
                    Debug.shared.log(message: "File does not exist during deletion: \(file.url.path)", type: .warning)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        // File doesn't exist, update UI anyway
                        self.updateUIAfterDeletion(file: file, index: index)
                        self.activityIndicator.stopAnimating()
                        
                        // Show warning
                        self.utilities.handleError(
                            in: self,
                            error: FileAppError.fileNotFound(file.name),
                            withTitle: "File Already Deleted"
                        )
                    }
                    return
                }
                
                // Perform the deletion
                try self.fileManager.removeItem(at: file.url)
                
                Debug.shared.log(message: "Successfully deleted: \(file.url.path)", type: .info)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Update the UI
                    self.updateUIAfterDeletion(file: file, index: index)
                    self.activityIndicator.stopAnimating()
                    
                    // Provide success feedback
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                }
            } catch {
                Debug.shared.log(message: "Error deleting file: \(error.localizedDescription)", type: .error)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: self, error: error, withTitle: "File Delete Error")
                }
            }
        }
    }
    
    /// Updates the UI after a file has been deleted
    /// - Parameters:
    ///   - file: The file that was deleted
    ///   - index: The index of the file
    private func updateUIAfterDeletion(file: File, index: Int) {
        // Update the appropriate file list
        if searchController.isActive {
            if let foundIndex = filteredFileList.firstIndex(of: file) {
                filteredFileList.remove(at: foundIndex)
                HomeViewUI.fileListTableView.deleteRows(at: [IndexPath(row: foundIndex, section: 0)], with: .fade)
            }
        } else {
            if index < fileList.count && fileList[index] == file {
                fileList.remove(at: index)
                HomeViewUI.fileListTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            } else if let foundIndex = fileList.firstIndex(of: file) {
                // Failsafe if index doesn't match
                fileList.remove(at: foundIndex)
                HomeViewUI.fileListTableView.deleteRows(at: [IndexPath(row: foundIndex, section: 0)], with: .fade)
            }
        }
        
        // Show empty state if necessary
        if fileList.isEmpty {
            showEmptyStateMessage()
        }
    }
    
    private func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .date:
            fileList.sort { $0.date > $1.date }
        case .size:
            fileList.sort { $0.size > $1.size }
        }
    }
    
    // MARK: - UI Actions
    @objc private func showMenu() {
        let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        let sortByNameAction = UIAlertAction(title: "Name", style: .default) { _ in
            self.sortOrder = .name
            self.sortFiles()
            HomeViewUI.fileListTableView.reloadData()
        }
        let sortByDateAction = UIAlertAction(title: "Date", style: .default) { _ in
            self.sortOrder = .date
            self.sortFiles()
            HomeViewUI.fileListTableView.reloadData()
        }
        let sortBySizeAction = UIAlertAction(title: "Size", style: .default) { _ in
            self.sortOrder = .size
            self.sortFiles()
            HomeViewUI.fileListTableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(sortByNameAction)
        alertController.addAction(sortByDateAction)
        alertController.addAction(sortBySizeAction)
        alertController.addAction(cancelAction)
        
        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(alertController, animated: true, completion: nil)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        filteredFileList = fileList.filter { $0.name.lowercased().contains(searchText) }
        HomeViewUI.fileListTableView.reloadData()
    }
    
    @objc private func addDirectory() {
        let alertController = UIAlertController(title: "Add Directory", message: "Enter the name of the new directory", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Directory Name"
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            guard let textField = alertController.textFields?.first,
                  let directoryName = textField.text?.trimmingCharacters(in: .whitespaces),
                  !directoryName.isEmpty else { return }
            
            let newDirectoryURL = self.documentsDirectory.appendingPathComponent(directoryName)
            do {
                try self.fileManager.createDirectory(at: newDirectoryURL, withIntermediateDirectories: false, attributes: nil)
                self.loadFiles()
                HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            } catch {
                self.utilities.handleError(in: self, error: error, withTitle: "Directory Creation Error")
            }
        }
        alertController.addAction(createAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func showFileOptions(for file: File) {
        let alertController = UIAlertController(title: "File Options", message: file.name, preferredStyle: .actionSheet)
        
        // Different options based on whether it's a directory or file
        if file.isDirectory {
            // Directory options
            let openAction = UIAlertAction(title: "Open", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.openFile(file)
            }
            
            let newFileAction = UIAlertAction(title: "Create New File", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.createNewFile(in: file)
            }
            
            let newFolderAction = UIAlertAction(title: "Create New Folder", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.createNewFolder(in: file)
            }
            
            let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.renameFile(file)
            }
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                if let index = self.fileList.firstIndex(of: file) {
                    self.deleteFile(at: index)
                }
            }
            
            let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.fileHandlers.shareFile(viewController: self, fileURL: file.url)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(openAction)
            alertController.addAction(newFileAction)
            alertController.addAction(newFolderAction)
            alertController.addAction(renameAction)
            alertController.addAction(deleteAction)
            alertController.addAction(shareAction)
            alertController.addAction(cancelAction)
        } else {
            // Regular file options
            let openAction = UIAlertAction(title: "Open", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.openFile(file)
            }
            
            let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.renameFile(file)
            }
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                if let index = self.fileList.firstIndex(of: file) {
                    self.deleteFile(at: index)
                }
            }
            
            let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.fileHandlers.shareFile(viewController: self, fileURL: file.url)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(openAction)
            alertController.addAction(renameAction)
            alertController.addAction(deleteAction)
            alertController.addAction(shareAction)
            alertController.addAction(cancelAction)
        }
        
        // Configure popover presentation on iPad
        if let popover = alertController.popoverPresentationController {
            if let cell = HomeViewUI.fileListTableView.cellForRow(at: IndexPath(row: self.fileList.firstIndex(of: file) ?? 0, section: 0)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            } else {
                // Fallback if cell isn't found
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func createNewFile(in directory: File? = nil) {
        let alertController = UIAlertController(title: "Create New File", message: "Enter a name for the new file", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "File Name (e.g., example.txt)"
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alertController.textFields?.first,
                  let fileName = textField.text?.trimmingCharacters(in: .whitespaces),
                  !fileName.isEmpty else { return }
            
            // Show loading indicator
            self.activityIndicator.startAnimating()
            
            // Determine parent directory
            let parentDirectory = directory?.url ?? self.documentsDirectory
            let fileURL = parentDirectory.appendingPathComponent(fileName)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create an empty file
                    let emptyContent = ""
                    
                    // Check if file exists
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.utilities.handleError(
                                in: self,
                                error: FileAppError.fileAlreadyExists(fileName),
                                withTitle: "File Creation Error"
                            )
                        }
                        return
                    }
                    
                    // Create the file
                    try emptyContent.write(to: fileURL, atomically: true, encoding: .utf8)
                    
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Ask if user wants to edit the file
                        let successAlert = UIAlertController(
                            title: "File Created",
                            message: "Would you like to edit this file now?",
                            preferredStyle: .alert
                        )
                        
                        successAlert.addAction(UIAlertAction(title: "Edit Now", style: .default) { _ in
                            let file = File(url: fileURL)
                            self.openFile(file)
                        })
                        
                        successAlert.addAction(UIAlertAction(title: "Later", style: .cancel))
                        
                        self.present(successAlert, animated: true, completion: nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.utilities.handleError(
                            in: self,
                            error: error,
                            withTitle: "File Creation Error"
                        )
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(createAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func createNewFolder(in directory: File? = nil) {
        let alertController = UIAlertController(title: "Create New Folder", message: "Enter a name for the new folder", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Folder Name"
            textField.autocapitalizationType = .none
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alertController.textFields?.first,
                  let folderName = textField.text?.trimmingCharacters(in: .whitespaces),
                  !folderName.isEmpty else { return }
            
            // Show loading indicator
            self.activityIndicator.startAnimating()
            
            // Determine parent directory
            let parentDirectory = directory?.url ?? self.documentsDirectory
            let folderURL = parentDirectory.appendingPathComponent(folderName)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Check if folder exists
                    if self.fileManager.fileExists(atPath: folderURL.path) {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.utilities.handleError(
                                in: self,
                                error: FileAppError.fileAlreadyExists(folderName),
                                withTitle: "Folder Creation Error"
                            )
                        }
                        return
                    }
                    
                    // Create the folder
                    try self.fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                    
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Show success alert
                        let successAlert = UIAlertController(
                            title: "Folder Created",
                            message: "The folder has been created successfully.",
                            preferredStyle: .alert
                        )
                        
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        
                        self.present(successAlert, animated: true, completion: nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.utilities.handleError(
                            in: self,
                            error: error,
                            withTitle: "Folder Creation Error"
                        )
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(createAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func renameFile(_ file: File) {
        let alertController = UIAlertController(title: "Rename \(file.isDirectory ? "Folder" : "File")", message: "Enter a new name", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = file.name
            textField.autocapitalizationType = .none
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alertController.textFields?.first,
                  let newName = textField.text?.trimmingCharacters(in: .whitespaces),
                  !newName.isEmpty,
                  newName != file.name else { return }
            
            // Show loading indicator
            self.activityIndicator.startAnimating()
            
            let parentDirectory = file.url.deletingLastPathComponent()
            let newURL = parentDirectory.appendingPathComponent(newName)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Check if destination already exists
                    if self.fileManager.fileExists(atPath: newURL.path) {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.utilities.handleError(
                                in: self,
                                error: FileAppError.fileAlreadyExists(newName),
                                withTitle: "Rename Error"
                            )
                        }
                        return
                    }
                    
                    // Perform the rename operation
                    try self.fileManager.moveItem(at: file.url, to: newURL)
                    
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.loadFiles() // Refresh to show renamed file
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Show success message
                        let alert = UIAlertController(
                            title: "Rename Successful",
                            message: "\(file.isDirectory ? "Folder" : "File") renamed to '\(newName)'",
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
                            withTitle: "Rename Error"
                        )
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(renameAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func openFile(_ file: File) {
        // Show loading indicator while preparing
        activityIndicator.startAnimating()
        
        // First check if file exists
        guard fileManager.fileExists(atPath: file.url.path) else {
            activityIndicator.stopAnimating()
            utilities.handleError(
                in: self,
                error: FileAppError.fileNotFound(file.name),
                withTitle: "File Not Found"
            )
            return
        }
        
        // Check if this is a directory
        if file.isDirectory {
            openDirectory(file)
            return
        }
        
        // For regular files, proceed based on file extension
        let fileExtension = file.url.pathExtension.lowercased()
        
        do {
            // Check if file is readable
            guard fileManager.isReadableFile(atPath: file.url.path) else {
                throw FileAppError.permissionDenied("Cannot read file: \(file.name)")
            }
            
            // Stop activity indicator before pushing new view controller
            activityIndicator.stopAnimating()
            
            // Open appropriate editor based on file type
            switch fileExtension {
            case "txt", "md", "swift", "h", "m", "c", "cpp", "js", "html", "css", "json", "strings":
                let editor = TextEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
            
            case "plist", "entitlements":
                let editor = PlistEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
            
            case "ipa":
                let editor = IPAEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
                
            case "zip", "gz", "tar", "7z":
                presentArchiveOptions(for: file)
                
            case "jpg", "jpeg", "png", "gif", "heic", "webp":
                presentImagePreview(for: file)
                
            default:
                let editor = HexEditorViewController(fileURL: file.url)
                navigationController?.pushViewController(editor, animated: true)
            }
        } catch {
            activityIndicator.stopAnimating()
            utilities.handleError(
                in: self,
                error: error,
                withTitle: "File Open Error"
            )
        }
    }
    
    private func openDirectory(_ directory: File) {
        Debug.shared.log(message: "Opening directory: \(directory.url.path)", type: .info)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Get contents of the directory with file attributes
                let contents = try self.fileManager.contentsOfDirectory(
                    at: directory.url,
                    includingPropertiesForKeys: [
                        .creationDateKey,
                        .contentModificationDateKey,
                        .fileSizeKey,
                        .isDirectoryKey
                    ],
                    options: .skipsHiddenFiles
                )
                
                // Create File objects for each item
                let files = contents.map { File(url: $0) }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Create a DirectoryViewController with the directory URL
                    let directoryVC = DirectoryViewController(directoryURL: directory.url, title: directory.name)
                    
                    // Set callback for when content changes
                    directoryVC.onContentChanged = { [weak self] in
                        // Reload the parent directory when content changes
                        self?.loadFiles()
                    }
                    
                    // Sort files using the same criteria as parent
                    directoryVC.sortOrder = self.sortOrder
                    directoryVC.sortFiles()
                    
                    // Stop activity indicator before pushing
                    self.activityIndicator.stopAnimating()
                    
                    // Push the directory view controller
                    self.navigationController?.pushViewController(directoryVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(
                        in: self,
                        error: error,
                        withTitle: "Directory Open Error"
                    )
                }
            }
        }
    }
    
    private func presentArchiveOptions(for file: File) {
        let alert = UIAlertController(
            title: "Archive Options",
            message: "What would you like to do with \(file.name)?",
            preferredStyle: .actionSheet
        )
        
        let extractAction = UIAlertAction(title: "Extract", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.extractArchive(file)
        }
        
        let viewAction = UIAlertAction(title: "View as Hex", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let editor = HexEditorViewController(fileURL: file.url)
            self.navigationController?.pushViewController(editor, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(extractAction)
        alert.addAction(viewAction)
        alert.addAction(cancelAction)
        
        // Handle iPad presentation
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func presentImagePreview(for file: File) {
        // For this implementation, we'll just show a simple alert that this feature is coming soon
        // In a full implementation, we would display the image in a proper image viewer
        let alert = UIAlertController(
            title: "Image Preview",
            message: "Image preview functionality will be available in a future update. Would you like to view this file as hex data?",
            preferredStyle: .alert
        )
        
        let viewHexAction = UIAlertAction(title: "View as Hex", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let editor = HexEditorViewController(fileURL: file.url)
            self.navigationController?.pushViewController(editor, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(viewHexAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func extractArchive(_ file: File) {
        // Show activity indicator
        activityIndicator.startAnimating()
        
        // Get destination directory name (remove extension from file name)
        let baseName = file.name.components(separatedBy: ".").dropLast().joined(separator: ".")
        let destinationName = baseName.isEmpty ? "Extracted_\(Int(Date().timeIntervalSince1970))" : baseName
        let destinationURL = documentsDirectory.appendingPathComponent(destinationName)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Check if destination already exists
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    // Create a unique name if needed
                    let uniqueName = self.getUniqueFileName(for: destinationName)
                    let uniqueURL = self.documentsDirectory.appendingPathComponent(uniqueName)
                    
                    // Create extraction directory
                    try self.fileManager.createDirectory(at: uniqueURL, withIntermediateDirectories: true, attributes: nil)
                    
                    // Extract archive
                    try self.fileManager.unzipItem(at: file.url, to: uniqueURL)
                    
                    // Success, update UI
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Show success alert
                        let alert = UIAlertController(
                            title: "Extraction Complete",
                            message: "Archive extracted to: \(uniqueName)",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    // Create extraction directory
                    try self.fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                    
                    // Extract archive
                    try self.fileManager.unzipItem(at: file.url, to: destinationURL)
                    
                    // Success, update UI
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        
                        // Show success alert
                        let alert = UIAlertController(
                            title: "Extraction Complete",
                            message: "Archive extracted to: \(destinationName)",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(
                        in: self,
                        error: error,
                        withTitle: "Extraction Error"
                    )
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFileList.count : fileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as? FileTableViewCell else {
            return UITableViewCell()
        }
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        cell.configure(with: file, in: self) { [weak self] in
            // Reload files when an action is performed through the context menu
            self?.loadFiles()
        }
        cell.backgroundColor = .clear
        cell.layer.cornerRadius = 10
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        // Instead of showing options, directly open the file for a more intuitive experience
        openFile(file)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
            self.present(activityViewController, animated: true)
            completion(true)
        }
        shareAction.backgroundColor = .systemBlue
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        
        // Rename action for quick editing
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            self.renameFile(file)
            completion(true)
        }
        renameAction.backgroundColor = .systemGreen
        renameAction.image = UIImage(systemName: "pencil")
        
        // Configure swipe actions
        let actions = [deleteAction, shareAction, renameAction]
        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: file.url.path as NSString))
        session.localContext = file.name
        return [dragItem]
    }
    
    // MARK: - UITableViewDropDelegate
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        tableHandlers.tableView(tableView, performDropWith: coordinator, fileList: &fileList, documentsDirectory: documentsDirectory, loadFiles: loadFiles)
    }
    
    // MARK: - FileHandlingDelegate
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Handle potentially multiple selected files
        guard !urls.isEmpty else {
            Debug.shared.log(message: "No files selected in document picker", type: .warning)
            return
        }
        
        Debug.shared.log(message: "Document picker selected \(urls.count) files", type: .info)
        
        // Process each file that was selected
        for url in urls {
            handleImportedFile(url: url)
            // Add a small delay between processing multiple files
            if urls.count > 1 && url != urls.last {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        Debug.shared.log(message: "Document picker was cancelled", type: .info)
        // Stop any loading indicators that might be active
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Private Methods
    private func applyFuturisticTransition() {
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = .fromTop
        transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
        view.layer.add(transition, forKey: nil)
    }
}

extension CALayer {
    func applyFuturisticShadow() {
        shadowColor = UIColor.systemCyan.withAlphaComponent(0.3).cgColor
        shadowOffset = CGSize(width: 0, height: 5)
        shadowRadius = 10
        shadowOpacity = 0.8
        masksToBounds = false
    }
}