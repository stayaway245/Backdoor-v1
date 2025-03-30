//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

//
//

import UIKit

// Extension to add protocol conformance to HomeViewController
extension HomeViewController {
    
    // MARK: - UITableViewDragDelegate
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let itemProvider = NSItemProvider(object: file.url as NSURL)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = file
        return [dragItem]
    }
    
    // MARK: - UITableViewDropDelegate
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // Implementation for drop handling
        coordinator.session.loadObjects(ofClass: NSURL.self) { items in
            guard let urls = items as? [URL] else { return }
            
            for url in urls {
                self.handleImportedFile(url: url)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
    }
}
