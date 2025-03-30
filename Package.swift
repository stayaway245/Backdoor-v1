// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Backdoor",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Backdoor",
            targets: ["Backdoor"]),
    ],
    dependencies: [
        // MARK: - Core Dependencies (Actually used in the codebase)
        
        // UI and Image handling
        .package(url: "https://github.com/kean/Nuke", from: "12.1.0"),        // Image loading and caching
        .package(url: "https://github.com/sparrowcode/AlertKit", from: "5.0.1"), // Alert presentations
        
        // Onboarding - Going back to the original package that was working
        .package(url: "https://github.com/khcrysalis/UIOnboarding-18", branch: "main"),
        
        // File and Archive Management
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.16"), // ZIP handling
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.0"),  // Archive decompression
        .package(url: "https://github.com/tsolomko/BitByteData", from: "2.0.1"),    // Required by SWCompression
        
        // Server and Networking
        .package(url: "https://github.com/vapor/vapor", from: "4.76.0"),            // Server-side Swift framework
        
        // Required Vapor dependencies
        .package(url: "https://github.com/vapor/async-http-client", from: "1.17.0"),
        .package(url: "https://github.com/vapor/websocket-kit", from: "2.13.0"),
        .package(url: "https://github.com/swift-server/async-kit", from: "1.17.0"),
        
        // Security and Encryption - Back to original
        .package(url: "https://github.com/HAHALOSAH/OpenSSL-Swift-Package", branch: "main"),
        
        // Networking and SSL
        .package(url: "https://github.com/apple/swift-nio", from: "2.54.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.23.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.17.0"),
        
        // MARK: - Recommended Additional Dependencies
        
        // Logging - Production-grade logging system
        .package(url: "https://github.com/apple/swift-log", from: "1.5.2"),
    ],
    targets: [
        .target(
            name: "Backdoor",
            dependencies: [
                // Core dependencies - actively used in codebase
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "NukeExtensions", package: "Nuke"),
                .product(name: "NukeVideo", package: "Nuke"),
                .product(name: "UIOnboarding", package: "UIOnboarding-18"),
                .product(name: "AlertKit", package: "AlertKit"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "BitByteData", package: "BitByteData"),
                
                // Server-side components
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "AsyncKit", package: "async-kit"),
                
                // Security and networking
                .product(name: "OpenSSL", package: "OpenSSL-Swift-Package"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                
                // Logging system
                .product(name: "Logging", package: "swift-log"),
            ],
            path: ".",
            exclude: [
                "README.md",
                "LICENSE",
                ".github",
                ".git",
                "backdoor.xcodeproj",
                "backdoor.xcworkspace",
                "scripts",
                "FAQ.md",
                "CODE_OF_CONDUCT.md",
                ".swiftformat",
                ".swiftlint.yml",
                ".clang-format",
                "Makefile",
                "Clean",
                "app-repo.json",
                "fix_license_headers.sh",
                "localization_changes.patch"
            ],
            swiftSettings: [
                // Debug optimization settings
                .define("DEBUG", .when(configuration: .debug)),
                .unsafeFlags(["-Onone"], .when(configuration: .debug)),
                
                // Release optimization settings
                .define("RELEASE", .when(configuration: .release)),
                .unsafeFlags(["-O"], .when(configuration: .release))
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
