# Getting Started

MuPDF Mobile is a cross-platform PDF library for **iOS** (Swift/Objective-C) and **Android** (Kotlin/Java). It wraps the [MuPDF](https://mupdf.com/) C engine, exposing a unified API on both platforms.

## Requirements

| Platform | Minimum version |
|---|---|
| iOS | 15.0 |
| macOS | 12.0 |
| Android | API 21 (Android 5.0) |
| Swift | 5.9+ |
| Kotlin | 1.9+ |

## Installation

### iOS — Swift Package Manager

Add the package in Xcode via **File → Add Package Dependencies…** and enter the URL:

```
https://github.com/farfromrefug/mupdf-mobile.git
```

Or add it directly to your `Package.swift`:

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

:::tip Submodule required
After adding the package, initialise the MuPDF C engine submodule:
```bash
git submodule update --init --recursive
```
:::

### Android — Gradle / Jitpack

Add the Jitpack repository to your project's `settings.gradle`:

```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

Then add the dependency in your module's `build.gradle`:

```groovy
dependencies {
    implementation 'com.github.farfromrefug:mupdf-mobile:1.0.0'
}
```

## Quick Start

### iOS (Swift)

```swift
import MuPDFMobile

// Open a document from the file system
let doc = try MuPDFDocument.open(path: "/path/to/document.pdf")
print("Pages: \(doc.pageCount)")

// Render the first page at 2× (Retina)
let page   = try doc.loadPage(at: 0)
let bitmap = page.render(scale: 2.0)
imageView.image = bitmap.image   // UIImageView

// Search for text and get hit rectangles
let hits = page.search(text: "MuPDF")
hits.forEach { rect in drawHighlight(rect) }

// Add a yellow highlight annotation
let rect  = MuPDFRect(x: 72, y: 100, width: 200, height: 20)
let annot = try page.addAnnotation(type: .highlight, rect: rect)
annot.color = MuPDFColor(r: 1, g: 1, b: 0, a: 0.5)
annot.update()

// Save and clean up
try doc.save(to: "/path/to/output.pdf")
doc.close()
```

### Android (Kotlin)

```kotlin
import com.artifex.mupdf.mobile.*

// Open a document — use 'use' for automatic resource cleanup
MuPDFDocument.open("/path/to/document.pdf").use { doc ->
    println("Pages: ${doc.pageCount}")

    // Render the first page at 2× density
    val page   = doc.loadPage(0)
    val bitmap = page.render(2f)
    imageView.setImageBitmap(bitmap.bitmap)   // ImageView

    // Search for text
    val hits = page.search("MuPDF")
    hits.forEach { rect -> drawHighlight(rect) }

    // Add a yellow highlight annotation
    val rect  = MuPDFRect(72f, 100f, 200f, 20f)
    val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, rect)
    annot.color = MuPDFColor(1f, 1f, 0f, 0.5f)
    annot.update()

    // Save (document is closed automatically by 'use')
    doc.save("/path/to/output.pdf")
}
```

## Next Steps

- **[Rendering Pages](./rendering)** — scale, tile-based rendering, and integration with scroll views
- **[Annotations](./annotations)** — all annotation types, add/edit/remove
- **[Document Editing](./editing)** — merge, split, insert images, redactions
- **[API Reference](/api/document)** — detailed method-level documentation
