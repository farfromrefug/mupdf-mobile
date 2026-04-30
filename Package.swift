// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// DocC documentation: run `swift package generate-documentation` or host via GitHub Pages.

import PackageDescription

let package = Package(
    name: "MuPDFMobile",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "MuPDFMobile",
            targets: ["MuPDFMobile"]
        ),
    ],
    targets: [
        .target(
            name: "MuPDFMobile",
            path: "Sources/MuPDFMobile",
            // When the mupdf submodule is initialised, add the following:
            //   cSettings: [.headerSearchPath("../../mupdf/include")],
            //   linkerSettings: [
            //     .linkedLibrary("mupdf", .when(platforms: [.iOS, .macOS])),
            //   ],
            swiftSettings: [
                .define("MUPDF_MOBILE"),
            ]
        ),
        .testTarget(
            name: "MuPDFMobileTests",
            dependencies: ["MuPDFMobile"],
            path: "Tests/MuPDFMobileTests"
        ),
    ]
)
