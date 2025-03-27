//
//  CoreDataManager+DownloadedApps.swift
//  feather
//
//  Created by samara on 8/2/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import CoreData

extension CoreDataManager {
	
	/// Clear all dl from Core Data and delete files
	func clearDownloadedApps(context: NSManagedObjectContext? = nil) throws {
        let context = context ?? self.context
        try clear(request: DownloadedApps.fetchRequest(), context: context)
	}
	
	/// Fetch all sources sorted alphabetically by name
	func getDatedDownloadedApps(context: NSManagedObjectContext? = nil) -> [DownloadedApps] {
        let request: NSFetchRequest<DownloadedApps> = DownloadedApps.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        do {
            return try (context ?? self.context).fetch(request)
        } catch {
            Debug.shared.log(message: "Error in getDatedDownloadedApps: \(error)", type: .error)
            return []
        }
	}
	
	/// Add application to downloaded apps
	func addToDownloadedApps(
		context: NSManagedObjectContext? = nil,
		version: String,
		name: String,
		bundleidentifier: String,
		iconURL: String?,
		dateAdded: Date? = Date(),
		uuid: String,
		appPath: String?,
		sourceLocation: String? = "Imported",
		sourceURL: URL? = nil,
		completion: @escaping (Error?) -> Void) {
            let context = context ?? self.context
            let newApp = DownloadedApps(context: context)
            
            newApp.version = version
            newApp.name = name
            newApp.bundleidentifier = bundleidentifier
            newApp.iconURL = iconURL
            newApp.dateAdded = dateAdded
            newApp.uuid = uuid
            newApp.appPath = appPath
            newApp.oSU = sourceURL?.absoluteString ?? sourceLocation
            
            do {
                try context.save()
                NotificationCenter.default.post(name: Notification.Name("lfetch"), object: nil)
                completion(nil)
            } catch {
                Debug.shared.log(message: "Error saving data: \(error)", type: .error)
                completion(error)
            }
	}
	
	/// Get application file path (non-throwing version for compatibility)
	// Use the throwing version and handle errors at call sites
	@available(*, deprecated, message: "Use the throwing version getFilesForDownloadedApps(for:getuuidonly:) in CoreDataManager instead")
	func getFilesForDownloadedApps(for app: DownloadedApps, getuuidonly: Bool = false) -> URL {
        do {
            return try CoreDataManager.shared.getFilesForDownloadedApps(for: app, getuuidonly: getuuidonly)
        } catch {
            Debug.shared.log(message: "Error in getFilesForDownloadedApps: \(error)", type: .error)
            // Return a fallback URL that doesn't crash when used, but clearly indicates an error
            return URL(fileURLWithPath: "")
        }
	}
    
    /// Get application file path with proper error handling (internal implementation)
    private func getFilesForDownloadedAppsWithThrow(for app: DownloadedApps, getuuidonly: Bool = false) throws -> URL {
        guard let uuid = app.uuid, let appPath = app.appPath, let dir = app.directory else {
            throw FileProcessingError.missingFile("Required app properties (uuid, appPath, or directory)")
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileProcessingError.missingFile("Documents directory")
        }
        
        var path = documentsDirectory
            .appendingPathComponent("Apps")
            .appendingPathComponent(dir)
            .appendingPathComponent(uuid)
        
        if !getuuidonly {
            path = path.appendingPathComponent(appPath)
            
            // Ensure directory exists
            let directoryPath = path.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directoryPath.path) {
                do {
                    try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true)
                } catch {
                    throw FileProcessingError.fileIOError(error)
                }
            }
        }
        
        return path
    }
	
	/// Delete a downloaded app (non-throwing version for compatibility)
	func deleteAllDownloadedAppContent(for app: DownloadedApps) {
        do {
            try deleteAllDownloadedAppContentWithThrow(for: app)
        } catch {
            Debug.shared.log(message: "CoreDataManager.deleteAllDownloadedAppContent: \(error)", type: .error)
        }
	}
    
    /// Delete a downloaded app with proper error handling
    func deleteAllDownloadedAppContentWithThrow(for app: DownloadedApps) throws {
        context.delete(app)
        let fileURL = try CoreDataManager.shared.getFilesForDownloadedApps(for: app, getuuidonly: true)
        try FileManager.default.removeItem(at: fileURL)
        try context.save()
    }
}
