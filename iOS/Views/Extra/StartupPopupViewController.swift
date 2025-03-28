import UIKit

/// A popup that displays for exactly 5 seconds on first app launch
class StartupPopupViewController: UIViewController {
    
    // MARK: - UI Components
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let iconImageView = UIImageView()
    private let progressView = UIProgressView()
    
    // MARK: - Properties
    private let displayDuration: TimeInterval = 5.0
    private var timer: Timer?
    private var startTime: Date?
    
    // Callback when popup is dismissed
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start the timer when the view appears
        startTime = Date()
        startProgressTimer()
        
        // Schedule automatic dismissal after exactly 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
            self?.dismissPopup()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Main view configuration
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Content view setup
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.layer.shadowRadius = 6
        view.addSubview(contentView)
        
        // Icon setup
        iconImageView.image = UIImage(named: "backdoor_glyph")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = Preferences.appTintColor.uiColor
        contentView.addSubview(iconImageView)
        
        // Title setup
        titleLabel.text = "Welcome to Backdoor"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        
        // Message setup
        messageLabel.text = "The best signer app for iOS"
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)
        
        // Progress view setup
        progressView.progressTintColor = Preferences.appTintColor.uiColor
        progressView.trackTintColor = .systemGray4
        progressView.progress = 0.0
        contentView.addSubview(progressView)
        
        // Setup auto layout
        setupConstraints()
    }
    
    private func setupConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Content view constraints - centered with fixed width
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 280),
            
            // Icon constraints
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 70),
            iconImageView.heightAnchor.constraint(equalToConstant: 70),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Message constraints
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Progress view constraints
            progressView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Timer Management
    private func startProgressTimer() {
        // Update progress every 0.1 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = Float(min(elapsedTime / self.displayDuration, 1.0))
            
            DispatchQueue.main.async {
                self.progressView.progress = progress
            }
            
            // Stop the timer if progress is complete
            if progress >= 1.0 {
                self.timer?.invalidate()
            }
        }
    }
    
    private func dismissPopup() {
        timer?.invalidate()
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false) {
                self.onDismiss?()
            }
        }
    }
    
    // MARK: - Overrides
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Prevent user interaction by consuming touch events
        // Do not call super to prevent the touch from being processed
    }
}
