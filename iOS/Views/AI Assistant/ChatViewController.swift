//
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISheetPresentationControllerDelegate {
    // MARK: - UI Components
    private let tableView = UITableView()
    private let inputContainer = UIView()
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Data
    public var currentSession: ChatSession  // Public to allow access from FloatingButtonManager
    private var messages: [ChatMessage] = []
    
    // Thread-safe state management
    private let stateQueue = DispatchQueue(label: "com.backdoor.chatViewControllerState", qos: .userInteractive)
    private var _isProcessingMessage = false
    private var isProcessingMessage: Bool {
        get { stateQueue.sync { return _isProcessingMessage } }
        set { stateQueue.sync { _isProcessingMessage = newValue } }
    }
    
    // MARK: - Callbacks
    /// Called when the view controller is dismissed - used by FloatingButtonManager to reset state
    var dismissHandler: (() -> Void)?
    
    // MARK: - Initialization
    init(session: ChatSession? = nil) {
        if let session = session {
            self.currentSession = session
        } else {
            // Create a new session with current date/time
            let title = "Chat on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
            do {
                self.currentSession = try CoreDataManager.shared.createAIChatSession(title: title)
            } catch {
                Debug.shared.log(message: "Failed to create chat session: \(error)", type: .error)
                // Fallback with empty session - this is a safety measure
                self.currentSession = ChatSession()
            }
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMessages()
        
        // Register for app background/foreground notifications
        setupAppStateObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set navigation bar appearance
        if let navigationController = navigationController {
            navigationController.navigationBar.prefersLargeTitles = false
            navigationController.navigationBar.isTranslucent = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // If we're being dismissed (not just covered by another VC), call the dismissHandler
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            dismissHandler?()
        }
    }
    
    deinit {
        // Clean up notification observers to prevent memory leaks
        NotificationCenter.default.removeObserver(self)
        Debug.shared.log(message: "ChatViewController deinit", type: .debug)
    }
    
    // MARK: - App State Handling
    private func setupAppStateObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        // Save any pending state when app goes to background
        Debug.shared.log(message: "Chat view controller saving state before background", type: .debug)
        
        // Cancel any ongoing message processing
        if isProcessingMessage {
            // We'll let the ongoing process complete but ensure UI is updated on return
            Debug.shared.log(message: "App entering background while processing message", type: .debug)
        }
    }
    
    @objc private func appWillEnterForeground() {
        // Refresh data when app comes to foreground
        Debug.shared.log(message: "Chat view controller becoming active after background", type: .debug)
        
        // Refresh messages to ensure we're in sync with CoreData
        DispatchQueue.main.async { [weak self] in
            self?.loadMessages()
            
            // Re-enable UI if it was left in a processing state
            if let self = self, self.isProcessingMessage {
                self.activityIndicator.stopAnimating()
                self.sendButton.isEnabled = true
                self.textField.isEnabled = true
                self.isProcessingMessage = false
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.title = currentSession.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "clock.arrow.circlepath"),
            style: .plain,
            target: self,
            action: #selector(showHistory)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.bubble"),
            style: .plain,
            target: self,
            action: #selector(newChat)
        )
        
        // Table view for messages
        setupTableView()
        
        // Input controls
        setupInputControls()
        
        // Layout constraints
        setupConstraints()
        
        // Keyboard handling
        setupKeyboardHandling()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register cell types
        tableView.register(UserMessageCell.self, forCellReuseIdentifier: "UserCell")
        tableView.register(AIMessageCell.self, forCellReuseIdentifier: "AICell")
        tableView.register(SystemMessageCell.self, forCellReuseIdentifier: "SystemCell")
        
        // Configure tableView appearance
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = .systemGray6
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        
        // iOS 15+ specific customization
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        view.addSubview(tableView)
    }
    
    private func setupInputControls() {
        // Input container
        inputContainer.backgroundColor = .systemBackground
        inputContainer.layer.shadowColor = UIColor.black.cgColor
        inputContainer.layer.shadowOpacity = 0.1
        inputContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        inputContainer.layer.shadowRadius = 4
        view.addSubview(inputContainer)
        
        // Text field
        textField.placeholder = "Ask me anything..."
        textField.borderStyle = .roundedRect
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.returnKeyType = .send
        textField.delegate = self
        textField.autocorrectionType = .default
        textField.spellCheckingType = .default
        textField.enablesReturnKeyAutomatically = true
        inputContainer.addSubview(textField)
        
        // Send button
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputContainer.addSubview(sendButton)
        
        // Activity indicator
        activityIndicator.color = .systemGray
        activityIndicator.hidesWhenStopped = true
        inputContainer.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        // Enable autolayout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Safe area guide for proper layout
        let safeArea = view.safeAreaLayoutGuide
        
        // Apply constraints
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            
            // Input container
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Text field
            textField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: activityIndicator.leadingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            
            // Activity indicator
            activityIndicator.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            activityIndicator.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor)
        ])
    }
    
    private func setupKeyboardHandling() {
        // Add keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Add tap gesture recognizer to dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.inputContainer.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            self.tableView.contentInset.bottom = keyboardHeight + 60
            self.scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.inputContainer.transform = .identity
            self.tableView.contentInset.bottom = 0
            self.scrollToBottom()
        }
    }
    
    // MARK: - Data Loading
    private func loadMessages() {
        // Fetch messages from CoreData
        let fetchedMessages = CoreDataManager.shared.getMessages(for: currentSession)
        
        // Handle the case where no messages are found
        if fetchedMessages.isEmpty && messages.isEmpty {
            Debug.shared.log(message: "No messages found for chat session", type: .debug)
        } else {
            messages = fetchedMessages
            tableView.reloadData()
            scrollToBottom(animated: false)
        }
    }
    
    private func scrollToBottom(animated: Bool = true) {
        // Ensure we have messages and the table view is loaded
        if !messages.isEmpty && tableView.window != nil {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            
            // Safely scroll to bottom
            if indexPath.row < tableView.numberOfRows(inSection: 0) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func showHistory() {
        let historyVC = ChatHistoryViewController()
        historyVC.didSelectSession = { [weak self] session in
            self?.loadSession(session)
        }
        let navController = UINavigationController(rootViewController: historyVC)
        
        // Use half sheet style on newer iOS versions
        if #available(iOS 15.0, *), let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        } else {
            navController.modalPresentationStyle = .formSheet
        }
        
        present(navController, animated: true)
    }
    
    @objc private func newChat() {
        // If already processing a message, don't allow creating a new chat
        if isProcessingMessage {
            Debug.shared.log(message: "Ignored new chat request while processing message", type: .warning)
            return
        }
        
        let title = "Chat on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        do {
            currentSession = try CoreDataManager.shared.createAIChatSession(title: title)
            messages = []
            tableView.reloadData()
            navigationItem.title = currentSession.title
            
            // Give feedback to user
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            Debug.shared.log(message: "Failed to create new chat session: \(error)", type: .error)
            showErrorAlert(message: "Failed to create new chat session")
        }
    }
    
    /// Load a different chat session
    func loadSession(_ session: ChatSession) {
        if isProcessingMessage {
            Debug.shared.log(message: "Ignored session change while processing message", type: .warning)
            return
        }
        
        currentSession = session
        loadMessages()
        navigationItem.title = session.title
    }
    
    @objc private func sendMessage() {
        // Ensure we're not already processing a message
        if isProcessingMessage {
            Debug.shared.log(message: "Ignored message send while already processing", type: .warning)
            return
        }
        
        // Get and validate text
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }
        
        // Clear text field immediately for better UX
        textField.text = ""
        
        // Update UI to show message sending
        activityIndicator.startAnimating()
        sendButton.isEnabled = false
        textField.isEnabled = false
        isProcessingMessage = true
        
        // Create a background task ID to handle possible app backgrounding during message processing
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            // If background time is about to expire, ensure we clean up
            self?.handleMessageProcessingTimeout()
            
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
        
        // Process message in a try-catch block for better error handling
        do {
            // Add user message to database and update UI
            let userMessage = try CoreDataManager.shared.addMessage(to: currentSession, sender: "user", content: text)
            messages.append(userMessage)
            tableView.reloadData()
            scrollToBottom()
            
            // Get current app context for AI relevance
            let context = AppContextManager.shared.currentContext()
            
            // Get additional context information from our custom provider
            let contextSummary = CustomAIContextProvider.shared.getContextSummary()
            Debug.shared.log(message: "AI context: \(contextSummary)", type: .debug)
            
            // Convert CoreData ChatMessages to payload format
            let apiMessages = messages.map { 
                OpenAIService.AIMessagePayload(
                    role: $0.sender == "user" ? "user" : ($0.sender == "ai" ? "assistant" : "system"), 
                    content: $0.content ?? ""
                ) 
            }
            
            // Create temporary "typing" indicator with delay to avoid flashing
            var typingMessageID: String? = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.isProcessingMessage else { return }
                
                do {
                    let typingMessage = try CoreDataManager.shared.addMessage(
                        to: self.currentSession,
                        sender: "system",
                        content: "Assistant is thinking..."
                    )
                    typingMessageID = typingMessage.messageID
                    self.messages.append(typingMessage)
                    self.tableView.reloadData()
                    self.scrollToBottom()
                } catch {
                    Debug.shared.log(message: "Failed to add typing indicator: \(error)", type: .debug)
                }
            }
            
            // Give haptic feedback when sending message
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Call AI service with proper error handling
            OpenAIService.shared.getAIResponse(messages: apiMessages, context: context) { [weak self] result in
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // Reset UI state
                    self.activityIndicator.stopAnimating()
                    self.sendButton.isEnabled = true
                    self.textField.isEnabled = true
                    self.isProcessingMessage = false
                    
                    // End background task if still active
                    if backgroundTaskID != .invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    
                    // Remove typing indicator if it exists
                    if let typingID = typingMessageID {
                        // Find and remove typing message from message array
                        if let index = self.messages.firstIndex(where: { $0.messageID == typingID }) {
                            self.messages.remove(at: index)
                        }
                        // Remove from database
                        CoreDataManager.shared.deleteMessage(withID: typingID)
                    }
                    
                    switch result {
                    case .success(let response):
                        do {
                            // Add AI message to database
                            let aiMessage = try CoreDataManager.shared.addMessage(
                                to: self.currentSession,
                                sender: "ai",
                                content: response
                            )
                            self.messages.append(aiMessage)
                            self.tableView.reloadData()
                            self.scrollToBottom()
                            
                            // Extract and process any commands in the response
                            self.processCommands(from: response)
                            
                            // Give haptic feedback for successful response
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        } catch {
                            Debug.shared.log(message: "Failed to add AI message: \(error)", type: .error)
                            self.showErrorAlert(message: "Failed to save AI response")
                        }
                    case .failure(let error):
                        do {
                            // Show error in chat
                            let errorMessage = try CoreDataManager.shared.addMessage(
                                to: self.currentSession, 
                                sender: "system", 
                                content: "Error: \(error.localizedDescription)"
                            )
                            self.messages.append(errorMessage)
                            self.tableView.reloadData()
                            self.scrollToBottom()
                            
                            // Provide a more helpful error message based on error type
                            if case OpenAIService.ServiceError.processingError(let reason) = error {
                                let helpMessage = try CoreDataManager.shared.addMessage(
                                    to: self.currentSession,
                                    sender: "system",
                                    content: "The assistant encountered a processing error: \(reason). Please try again with a different question."
                                )
                                self.messages.append(helpMessage)
                                self.tableView.reloadData()
                                self.scrollToBottom()
                            }
                            
                            // Haptic feedback for error
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        } catch {
                            Debug.shared.log(message: "Failed to add error message: \(error)", type: .error)
                            self.showErrorAlert(message: "Failed to save error message")
                        }
                    }
                }
            }
        } catch {
            // Handle failure to save user message
            self.activityIndicator.stopAnimating()
            self.sendButton.isEnabled = true
            self.textField.isEnabled = true
            self.isProcessingMessage = false
            
            // End background task if still active
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            
            Debug.shared.log(message: "Failed to add user message: \(error)", type: .error)
            showErrorAlert(message: "Failed to save your message")
        }
    }
    
    /// Handle timeout of message processing (e.g., when app is backgrounded for too long)
    private func handleMessageProcessingTimeout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isProcessingMessage else { return }
            
            // Reset UI state
            self.activityIndicator.stopAnimating()
            self.sendButton.isEnabled = true
            self.textField.isEnabled = true
            self.isProcessingMessage = false
            
            do {
                // Add a system message about the timeout
                let timeoutMessage = try CoreDataManager.shared.addMessage(
                    to: self.currentSession,
                    sender: "system",
                    content: "Message processing was interrupted. Please try again."
                )
                self.messages.append(timeoutMessage)
                self.tableView.reloadData()
                self.scrollToBottom()
            } catch {
                Debug.shared.log(message: "Failed to add timeout message: \(error)", type: .error)
            }
        }
    }
    
    // MARK: - Command Processing
    /// Process commands extracted from AI response
    private func processCommands(from response: String) {
        // Extract commands using regex
        let commands = extractCommands(from: response)
        
        // Process each command
        for (command, parameter) in commands {
            // Use weak self to prevent retain cycles
            AppContextManager.shared.executeCommand(command, parameter: parameter) { [weak self] commandResult in
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    let systemMessageContent: String
                    switch commandResult {
                    case .successWithResult(let message):
                        systemMessageContent = message
                    case .unknownCommand(let cmd):
                        systemMessageContent = "Unknown command: \(cmd)"
                    }
                    
                    do {
                        // Add system message showing command result
                        let systemMessage = try CoreDataManager.shared.addMessage(
                            to: self.currentSession, 
                            sender: "system", 
                            content: systemMessageContent
                        )
                        self.messages.append(systemMessage)
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    } catch {
                        Debug.shared.log(message: "Failed to add system message: \(error)", type: .error)
                    }
                }
            }
        }
    }
    
    // Extract commands from AI response text
    private func extractCommands(from text: String) -> [(command: String, parameter: String)] {
        let pattern = "\\[([^:]+):([^\\]]+)\\]"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return matches.compactMap { match in
                if let commandRange = Range(match.range(at: 1), in: text),
                   let paramRange = Range(match.range(at: 2), in: text) {
                    return (String(text[commandRange]), String(text[paramRange]))
                }
                return nil
            }
        } catch {
            Debug.shared.log(message: "Failed to create regex for command extraction: \(error)", type: .error)
            return []
        }
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Check if we can present the alert
        if !isBeingDismissed && !isBeingPresented && presentedViewController == nil {
            present(alert, animated: true)
        } else {
            Debug.shared.log(message: "Could not present error alert: \(message)", type: .error)
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < messages.count else {
            return UITableViewCell() // Safety check
        }
        
        let message = messages[indexPath.row]
        switch message.sender {
        case "user":
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserMessageCell
            cell.configure(with: message)
            return cell
        case "ai":
            let cell = tableView.dequeueReusableCell(withIdentifier: "AICell", for: indexPath) as! AIMessageCell
            cell.configure(with: message)
            return cell
        case "system":
            let cell = tableView.dequeueReusableCell(withIdentifier: "SystemCell", for: indexPath) as! SystemMessageCell
            cell.configure(with: message)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - UISheetPresentationControllerDelegate
    
    // Handle sheet dismissal properly
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissHandler?()
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}