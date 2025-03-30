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
        // UI and Image handling
        .package(url: "https://github.com/kean/Nuke", from: "12.0.0"),
        .package(url: "https://github.com/khcrysalis/UIOnboarding-18", branch: "main"),
        .package(url: "https://github.com/sparrowcode/AlertKit", from: "5.0.0"),
        
        // Enhanced UI Components
        .package(url: "https://github.com/lkzhao/Hero", from: "1.6.0"),           // Advanced animations and transitions
        .package(url: "https://github.com/OrkhanAlikhanov/SwiftUI-Shimmer", from: "1.0.0"), // Shimmer loading effects
        .package(url: "https://github.com/exyte/PopupView", from: "2.0.0"),       // Better popup handling
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.0.0"),     // Lottie animations
        
        // File and Data Management
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.0"),
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.0.0"),
        .package(url: "https://github.com/tsolomko/BitByteData", from: "2.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),      // SQL database for better performance
        .package(url: "https://github.com/bitwit/swift-filemanagement-helper", from: "0.0.3"), // File management utilities
        
        // Networking and API
        .package(url: "https://github.com/vapor/vapor", from: "4.0.0"),
        .package(url: "https://github.com/vapor/async-http-client", from: "1.0.0"),
        .package(url: "https://github.com/vapor/websocket-kit", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/async-kit", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "8.0.0"),      // Promise-based async code
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),  // Enhanced networking
        
        // Security and encryption
        .package(url: "https://github.com/HAHALOSAH/OpenSSL-Swift-Package", branch: "main"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.8.0"), // Advanced crypto operations
        .package(url: "https://github.com/lukaskubanek/LoremSwiftum", from: "2.0.0"), // Generate test data
        
        // Debugging and Analytics
        .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver", from: "2.0.0"), // Better logging
        .package(url: "https://github.com/johnno1962/SwiftTrace", branch: "main"),   // Runtime tracing
        .package(url: "https://github.com/marcosgriselli/ViewInspector", from: "0.9.0"), // Testing SwiftUI views
        
        // Swift Foundation
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-metrics", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-http2", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.0.0"),
        
        // AI and Machine Learning
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.0"), // ML models for enhanced AI
    ],
    targets: [
        .target(
            name: "Backdoor",
            dependencies: [
                // Original dependencies
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "NukeExtensions", package: "Nuke"),
                .product(name: "NukeVideo", package: "Nuke"),
                .product(name: "UIOnboarding", package: "UIOnboarding-18"),
                .product(name: "AlertKit", package: "AlertKit"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "BitByteData", package: "BitByteData"),
                .product(name: "OpenSSL", package: "OpenSSL-Swift-Package"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                
                // Enhanced UI Components
                .product(name: "Hero", package: "Hero"),
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                .product(name: "PopupView", package: "PopupView"),
                .product(name: "Lottie", package: "lottie-ios"),
                
                // File and Data Management
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SwiftFileManagement", package: "swift-filemanagement-helper"),
                
                // Networking and API
                .product(name: "PromiseKit", package: "PromiseKit"),
                .product(name: "Alamofire", package: "Alamofire"),
                
                // Security and encryption
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "LoremSwiftum", package: "LoremSwiftum"),
                
                // Debugging and Analytics
                .product(name: "SwiftyBeaver", package: "SwiftyBeaver"),
                .product(name: "SwiftTrace", package: "SwiftTrace"),
                .product(name: "ViewInspector", package: "ViewInspector"),
                
                // AI and Machine Learning
                .product(name: "Transformers", package: "swift-transformers"),
            ],
            path: ".",
            exclude: [
                "README.md",
                "LICENSE",
                ".github",
                ".git",
                "backdoor.xcodeproj",
                "backdoor.xcworkspace"
            ],
            swiftSettings: [
                // Optimization settings to ensure compatibility with development environment
                .define("DEBUG", .when(configuration: .debug)),
                .unsafeFlags(["-Onone"], .when(configuration: .debug))
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
