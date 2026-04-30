<p align="center">
  <img src="docs/logo.svg" alt="MuPDF Mobile" width="120" />
</p>

<h1 align="center">MuPDF Mobile</h1>

<p align="center">
  A cross-platform mobile library that wraps <a href="https://mupdf.com/">MuPDF</a> for <strong>iOS</strong> (Swift/ObjC) and <strong>Android</strong> (Kotlin/JNI) with a unified API.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0-blue.svg" alt="License: AGPL-3.0"></a>
  <img src="https://img.shields.io/badge/platform-iOS%2015%2B-lightgrey.svg" alt="iOS 15+">
  <img src="https://img.shields.io/badge/platform-Android%2021%2B-lightgrey.svg" alt="Android 21+">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-FA7343.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Kotlin-1.9%2B-7F52FF.svg" alt="Kotlin 1.9+">
  <img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg" alt="SPM Compatible">
  <img src="https://img.shields.io/badge/Jitpack-compatible-brightgreen.svg" alt="Jitpack Compatible">
</p>

---

## Overview

**MuPDF Mobile** is a lightweight, production-ready wrapper around the battle-tested [MuPDF](https://mupdf.com/) rendering engine by Artifex Software. It exposes an idiomatic, identical API on both iOS (Swift + Objective-C) and Android (Kotlin + JNI), making it straightforward to build cross-platform PDF viewers and editors.

## Features

- 📄 **PDF rendering** — render any page to a bitmap at arbitrary scale or pixel dimensions
- 🗂 **Document management** — open from file path or in-memory data, merge, split, reorder pages
- ✏️ **Annotations** — add, edit, and remove highlights, ink, stamps, redactions, and more
- 🔍 **Text search** — full-text search with rectangle results for hit highlighting
- 🧩 **Tiled rendering** — efficient tile-based rendering for large pages in scroll/zoom views
- ✂️ **Editing** — insert images, apply redactions, insert/delete pages
- 🏎 **Swift & Kotlin native** — no JS bridge, no cross-compilation quirks
- 🔗 **ObjC compatible** — full `@objc` surface for legacy Objective-C projects
- 📦 **SPM + Jitpack** — first-class package manager support on both platforms

---

## Installation

### iOS — Swift Package Manager

Add the package in Xcode via **File → Add Packages…** or in your `Package.swift`:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/farfromrefug/mupdf-mobile.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "MuPDFMobile", package: "mupdf-mobile"),
        ]
    ),
]
```

> **Note:** After adding the package, initialise the MuPDF submodule:
> ```bash
> git submodule update --init --recursive
> ```

### Android — Gradle / Jitpack

Add the Jitpack repository and the dependency:

```groovy
// settings.gradle (or build.gradle for older setups)
dependencyResolutionManagement {
    repositories {
        maven { url 'https://jitpack.io' }
    }
}

// app/build.gradle
dependencies {
    implementation 'com.github.farfromrefug:mupdf-mobile:1.0.0'
}
```

---

## Quick Start

### iOS

```swift
import MuPDFMobile

// Open a document
let doc = try MuPDFDocument.open(path: "/path/to/document.pdf")
print("Pages: \(doc.pageCount)")

// Render page 0 at 2× scale
let page = try doc.loadPage(at: 0)
let bitmap = page.render(scale: 2.0)
imageView.image = bitmap.image

// Text search
let hits = page.search(text: "MuPDF")
hits.forEach { rect in
    print("Hit at \(rect)")
}

// Add a highlight annotation
let rect = MuPDFRect(x: 72, y: 100, width: 200, height: 20)
let annotation = try page.addAnnotation(type: .highlight, rect: rect)
annotation.color = MuPDFColor(r: 1, g: 1, b: 0, a: 0.5)
annotation.update()

doc.close()
```

### Android

```kotlin
import com.artifex.mupdf.mobile.*

// Open a document
val doc = MuPDFDocument.open("/path/to/document.pdf")
println("Pages: ${doc.pageCount}")

// Render page 0 at 2× scale
val page = doc.loadPage(0)
val bitmap = page.render(2.0f)
imageView.setImageBitmap(bitmap.bitmap)

// Text search
val hits = page.search("MuPDF")
hits.forEach { rect -> println("Hit at $rect") }

// Add a highlight annotation
val rect = MuPDFRect(72f, 100f, 200f, 20f)
val annotation = page.addAnnotation(MuPDFAnnotationType.Highlight, rect)
annotation.color = MuPDFColor(1f, 1f, 0f, 0.5f)
annotation.update()

doc.close()
```

---

## API Overview

| Class | iOS (Swift) | Android (Kotlin) | Description |
|---|---|---|---|
| `MuPDFDocument` | ✅ | ✅ | Open, save, merge, edit documents |
| `MuPDFPage` | ✅ | ✅ | Render, search, annotate pages |
| `MuPDFAnnotation` | ✅ | ✅ | Create and edit annotations |
| `MuPDFRenderer` | ✅ | ✅ | Utility for tiled/scaled rendering |
| `MuPDFEditor` | ✅ | ✅ | Insert images, apply redactions |
| `MuPDFBitmap` | ✅ (`UIImage`) | ✅ (`Bitmap`) | Platform bitmap wrapper |
| `MuPDFRect` | ✅ | ✅ | Rectangle value type |
| `MuPDFColor` | ✅ | ✅ | RGBA colour value type |
| `MuPDFAnnotationType` | ✅ | ✅ | Annotation type enum |

---

## Architecture

```
mupdf-mobile/
├── mupdf/                    ← MuPDF C engine (git submodule)
├── Sources/MuPDFMobile/      ← iOS Swift library (SPM)
│   ├── Internal/             ← C context wrapper, bridging helpers
│   └── *.swift               ← Public Swift API
├── Tests/MuPDFMobileTests/   ← Swift unit tests
├── android/lib/              ← Android Kotlin library (AAR)
│   ├── src/main/cpp/         ← JNI C++ bridge → MuPDF C
│   └── src/main/kotlin/      ← Public Kotlin API
├── demo/ios/                 ← Sample iOS app
├── demo/android/             ← Sample Android app
├── scripts/                  ← Build automation
└── docs/                     ← Documentation website
```

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Application                          │
├──────────────────────┬──────────────────────────────────────┤
│   iOS (Swift/ObjC)   │        Android (Kotlin/Java)         │
│  Sources/MuPDFMobile │   android/lib/src/main/kotlin/…      │
├──────────────────────┴──────────────────────────────────────┤
│              JNI Bridge  (mupdf_jni.cpp)                     │
│          [Android only — iOS links MuPDF directly]           │
├─────────────────────────────────────────────────────────────┤
│              MuPDF C Engine  (git submodule)                 │
│         mupdf/  — libmupdf.a / libmupdf.so                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Building from Source

### Prerequisites

| Tool | Version |
|---|---|
| Xcode | 15+ |
| Swift | 5.9+ |
| Android Studio | Hedgehog+ |
| NDK | r25+ |
| CMake | 3.22+ |
| Gradle | 8.x |

### Clone with submodules

```bash
git clone --recurse-submodules https://github.com/farfromrefug/mupdf-mobile.git
cd mupdf-mobile
```

### Build everything

```bash
./scripts/build.sh
```

### iOS only

```bash
./scripts/build-ios.sh
# Output: build/ios/MuPDFMobile.xcframework
```

### Android only

```bash
./scripts/build-android.sh
# Output: android/lib/build/outputs/aar/lib-release.aar
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes with clear messages
4. Open a Pull Request

For major changes please open an issue first to discuss what you would like to change.

---

## License

This project is licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0), the same license as MuPDF itself. See [LICENSE](LICENSE) for the full text.

For commercial licensing options (proprietary apps), please contact [Artifex Software](https://artifex.com/licensing/).
