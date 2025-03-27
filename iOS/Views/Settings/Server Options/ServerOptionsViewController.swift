//
//  ServerOptionsViewController.swift
//  feather
//
//  Created by samara on 22.10.2024.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import UIKit
import SwiftUI

class ServerOptionsViewController: FRSTableViewController {
	
	var isDownloadingCertifcate = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableData = [
			[
				"App Updates"
			],
			[
				"Use Server",
				String.localized("SETTINGS_VIEW_CONTROLLER_CELL_USE_CUSTOM_SERVER")
			],
            [
                "OpenRouter API Key"
            ],
			[
				String.localized("SETTINGS_VIEW_CONTROLLER_CELL_UPDATE_LOCAL_CERTIFICATE")
			],
		]
		
		sectionTitles =
		[
			"",
			String.localized("SETTINGS_VIEW_CONTROLLER_TITLE_ONLINE"),
            "AI Assistant Configuration",
			String.localized("SETTINGS_VIEW_CONTROLLER_TITLE_LOCAL"),
		]
		
        title = String.localized("SETTINGS_VIEW_CONTROLLER_TITLE")
		updateCells()
	}
}

extension ServerOptionsViewController {
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case 0: return "Whether updates should be checked, this is an experimental feature."
		case 1: return String.localized("SETTINGS_VIEW_CONTROLLER_SECTION_FOOTER_DEFAULT_SERVER", arguments: Preferences.defaultInstallPath)
        case 2: return "Configure your OpenRouter API key for AI assistant functionality."
		case 3: return String.localized("SETTINGS_VIEW_CONTROLLER_SECTION_FOOTER_SERVER_LIMITATIONS")
		default:
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
		cell.accessoryType = .none
		cell.selectionStyle = .none
		
		let cellText = tableData[indexPath.section][indexPath.row]
		cell.textLabel?.text = cellText
		
		switch cellText {
		case "App Updates":
			let useS = SwitchViewCell()
			useS.textLabel?.text = "Check For Signed App Updates"
			useS.switchControl.addTarget(self, action: #selector(appUpdates(_:)), for: .valueChanged)
			useS.switchControl.isOn = Preferences.appUpdates
			useS.selectionStyle = .none
			return useS
		case "Use Server":
			let useS = SwitchViewCell()
			useS.textLabel?.text = String.localized("SETTINGS_VIEW_CONTROLLER_CELL_ONLINE_INSTALL_METHOD")
			useS.switchControl.addTarget(self, action: #selector(onlinePathToggled(_:)), for: .valueChanged)
			useS.switchControl.isOn = Preferences.userSelectedServer
			useS.selectionStyle = .none
			return useS
		case String.localized("SETTINGS_VIEW_CONTROLLER_CELL_USE_CUSTOM_SERVER"):
			if Preferences.onlinePath != Preferences.defaultInstallPath {
				cell.textLabel?.textColor = UIColor.systemGray
				cell.isUserInteractionEnabled = false
				cell.textLabel?.text = Preferences.onlinePath!
			} else {
				cell.textLabel?.textColor = .tintColor
				cell.selectionStyle = .default
			}
		case String.localized("SETTINGS_VIEW_CONTROLLER_CELL_RESET_CONFIGURATION"):
			cell.textLabel?.textColor = .systemRed
			cell.textLabel?.textAlignment = .center
			cell.selectionStyle = .default
            
        case "OpenRouter API Key":
            // Check if API key is set
            var detailText = "Not Configured"
            do {
                // Just check if the key exists, don't actually display it
                _ = try KeychainManager.shared.getString(forKey: "openrouter_api_key")
                detailText = "Configured ✓"
                cell.detailTextLabel?.text = detailText
                cell.detailTextLabel?.textColor = .systemGreen
            } catch {
                cell.detailTextLabel?.text = detailText
                cell.detailTextLabel?.textColor = .systemRed
            }
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
			
		case String.localized("SETTINGS_VIEW_CONTROLLER_CELL_UPDATE_LOCAL_CERTIFICATE"):
			if !isDownloadingCertifcate {
				cell.textLabel?.textColor = .tintColor
				cell.setAccessoryIcon(with: "signature")
				cell.selectionStyle = .default
			} else {
				let cell = ActivityIndicatorViewCell()
				cell.activityIndicator.startAnimating()
				cell.selectionStyle = .none
				cell.textLabel?.text = String.localized("SETTINGS_VIEW_CONTROLLER_CELL_UPDATE_LOCAL_CERTIFICATE_UPDATING")
				cell.textLabel?.textColor = .secondaryLabel
				return cell
			}
		default:
			break
		}
		
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let itemTapped = tableData[indexPath.section][indexPath.row]
		switch itemTapped {
		case String.localized("SETTINGS_VIEW_CONTROLLER_CELL_USE_CUSTOM_SERVER"):
			showChangeDownloadURLAlert()
		case String.localized("SETTINGS_VIEW_CONTROLLER_CELL_RESET_CONFIGURATION"):
			resetConfigDefault()
		case String.localized("SETTINGS_VIEW_CONTROLLER_CELL_UPDATE_LOCAL_CERTIFICATE"):
			if !isDownloadingCertifcate {
				isDownloadingCertifcate = true
				defer {
					isDownloadingCertifcate = false
				}
				getCertificates()
			}
        case "OpenRouter API Key":
            showConfigureOpenRouterAPIKeyAlert()
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	@objc func appUpdates(_ sender: UISwitch) {
		Preferences.appUpdates = sender.isOn
	}
	
	@objc func onlinePathToggled(_ sender: UISwitch) {
		Preferences.userSelectedServer = sender.isOn
		
		let alertController = UIAlertController(
			title: "",
			message: String.localized("SUCCESS_REQUIRES_RESTART"),
			preferredStyle: .alert
		)
		
		let closeAction = UIAlertAction(title: String.localized("OK"), style: .default) { _ in
			CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
			UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
			exit(0)
		}
		
		alertController.addAction(closeAction)
		present(alertController, animated: true, completion: nil)
	}
	
	private func updateCells() {
		if Preferences.onlinePath != Preferences.defaultInstallPath {
			tableData[1].insert(String.localized("SETTINGS_VIEW_CONTROLLER_CELL_RESET_CONFIGURATION"), at: 2)
		}
		Preferences.installPathChangedCallback = { [weak self] newInstallPath in
			self?.handleInstallPathChange(newInstallPath)
		}
	}
	
	private func handleInstallPathChange(_ newInstallPath: String?) {
		if newInstallPath != Preferences.defaultInstallPath {
			tableData[1].insert(String.localized("SETTINGS_VIEW_CONTROLLER_CELL_RESET_CONFIGURATION"), at: 2)
		} else {
			if let index = tableData[1].firstIndex(of: String.localized("SETTINGS_VIEW_CONTROLLER_CELL_RESET_CONFIGURATION")) {
				tableData[1].remove(at: index)
			}
		}

		tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
	}
}

extension ServerOptionsViewController {
	func resetConfigDefault() {
		Preferences.onlinePath = Preferences.defaultInstallPath
	}
	
	func showChangeDownloadURLAlert() {
		let alert = UIAlertController(title: String.localized("SETTINGS_VIEW_CONTROLLER_URL_ALERT_TITLE"), message: nil, preferredStyle: .alert)

		alert.addTextField { textField in
			textField.placeholder = Preferences.defaultInstallPath
			textField.autocapitalizationType = .none
			textField.addTarget(self, action: #selector(self.textURLDidChange(_:)), for: .editingChanged)
		}

		let setAction = UIAlertAction(title: String.localized("SET"), style: .default) { _ in
			guard let textField = alert.textFields?.first, let enteredURL = textField.text else { return }

			Preferences.onlinePath = enteredURL
		}

		setAction.isEnabled = false
		let cancelAction = UIAlertAction(title: String.localized("CANCEL"), style: .cancel, handler: nil)

		alert.addAction(setAction)
		alert.addAction(cancelAction)
		present(alert, animated: true, completion: nil)
	}
    
    func showConfigureOpenRouterAPIKeyAlert() {
        let alert = UIAlertController(title: "OpenRouter API Key", message: "Enter your OpenRouter API key to enable AI assistant functionality", preferredStyle: .alert)
        
        var currentKey = ""
        do {
            currentKey = try KeychainManager.shared.getString(forKey: "openrouter_api_key")
        } catch {
            currentKey = ""
        }

        alert.addTextField { textField in
            textField.placeholder = "sk-or-v1-..."
            textField.text = currentKey
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.isSecureTextEntry = true
            textField.clearButtonMode = .whileEditing
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first, let apiKey = textField.text, !apiKey.isEmpty else {
                // If empty, show an alert asking if they want to remove the key
                self?.confirmRemoveAPIKey()
                return
            }
            
            // Save the API key in the keychain
            do {
                try KeychainManager.shared.saveString(apiKey, forKey: "openrouter_api_key")
                // Update the OpenRouterService with the new key
                OpenRouterService.shared.updateAPIKey(apiKey)
                Debug.shared.log(message: "OpenRouter API key saved successfully", type: .success)
                self?.tableView.reloadData()
            } catch {
                Debug.shared.log(message: "Failed to save OpenRouter API key: \(error)", type: .error)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // If there's a key set, add a "Remove" button
        if !currentKey.isEmpty {
            let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
                self?.confirmRemoveAPIKey()
            }
            alert.addAction(removeAction)
        }

        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func confirmRemoveAPIKey() {
        let confirm = UIAlertController(title: "Remove API Key?", message: "Are you sure you want to remove the OpenRouter API key? This will disable AI assistant functionality.", preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            do {
                try KeychainManager.shared.deleteValue(forKey: "openrouter_api_key")
                // Update the service with an empty key
                OpenRouterService.shared.updateAPIKey("")
                Debug.shared.log(message: "OpenRouter API key removed", type: .success)
                self?.tableView.reloadData()
            } catch {
                Debug.shared.log(message: "Failed to remove OpenRouter API key: \(error)", type: .error)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        confirm.addAction(removeAction)
        confirm.addAction(cancelAction)
        present(confirm, animated: true, completion: nil)
    }

	@objc func textURLDidChange(_ textField: UITextField) {
		guard let alertController = presentedViewController as? UIAlertController, let setAction = alertController.actions.first(where: { $0.title == String.localized("SET") }) else { return }

		let enteredURL = textField.text ?? ""
		setAction.isEnabled = isValidURL(enteredURL)
	}

	func isValidURL(_ url: String) -> Bool {
		let urlPredicate = NSPredicate(format: "SELF MATCHES %@", "https://.+")
		return urlPredicate.evaluate(with: url)
	}
}
