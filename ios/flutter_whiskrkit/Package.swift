// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_whiskrkit",
    platforms: [
        // WhiskrKit requires iOS 17.
        .iOS("17.0")
    ],
    products: [
        .library(name: "flutter-whiskrkit", targets: ["flutter_whiskrkit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // The native WhiskrKit SDK. 0.2.0 adds the attributes and the
        // onSurveyCompleted callback this plugin bridges.
        .package(url: "https://github.com/whiskrkit/whiskrkit-swift.git", exact: "0.2.0")
    ],
    targets: [
        .target(
            name: "flutter_whiskrkit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "WhiskrKit", package: "whiskrkit-swift")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
