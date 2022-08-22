// swift-tools-version:5.6
import PackageDescription

let toolchain:String = "swift-DEVELOPMENT-SNAPSHOT-2022-08-15-a"

let package:Package = .init(
    name: "swift-package-factory",
    platforms: 
    [
        .macOS(.v11)
    ],
    products: 
    [
        .executable(name: "swift-package-factory",  targets: ["swift-package-factory"]),
        .library(name: "Factory",                   targets: ["Factory"]),
        .plugin(name: "FactoryPlugin",              targets: ["FactoryPlugin"]),
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/swift-system-extras.git", from: "0.2.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: toolchain),
    ],
    targets:
    [
        .target(name: "Factory", 
            dependencies: 
            [
                .product(name: "SystemExtras",          package: "swift-system-extras"),
                .product(name: "SwiftSyntax",           package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser",     package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder",    package: "swift-syntax"),
            ]), 
        .executableTarget(name: "swift-package-factory", 
            dependencies: 
            [
                .target(name: "Factory"),
            ]), 
        .plugin(name: "FactoryPlugin", 
            capability: .command(
                intent: .custom(verb: "factory", 
                    description: "generate swift sources from factory sources"), 
                permissions: 
                [
                    .writeToPackageDirectory(reason: "factory emits source files")
                ]),
            dependencies: 
            [
                .target(name: "swift-package-factory"),
            ]), 
        
        .target(name: "FactoryPluginValidExampleTarget", path: "Examples/ValidExamples"), 
        .target(name: "FactoryPluginInvalidExampleTarget", path: "Examples/InvalidExamples"), 
    ]
)
