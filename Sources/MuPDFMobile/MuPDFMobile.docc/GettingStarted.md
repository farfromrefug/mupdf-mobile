# Getting Started with MuPDF Mobile

Add PDF rendering and annotation capabilities to your iOS app in minutes.

## Installation

### Swift Package Manager

Add the package via **File → Add Package Dependencies…** in Xcode, or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/farfromrefug/mupdf-mobile.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "MuPDFMobile", package: "mupdf-mobile"),
    ]),
]
```

After adding the package, initialise the MuPDF submodule:

```bash
git submodule update --init --recursive
```

## Opening a Document

```swift
import MuPDFMobile

let doc = try MuPDFDocument.open(path: "/path/to/document.pdf")
print("Pages: \(doc.pageCount)")
```

## Rendering a Page

```swift
let page   = try doc.loadPage(at: 0)
let bitmap = page.render(scale: 2.0)   // 2× Retina
imageView.image = bitmap.image
```

> Tip: Always call ``MuPDFDocument/loadPage(at:)`` and render on a background thread — use `Task.detached` or `DispatchQueue.global`.

## Searching Text

```swift
let hits = page.search(text: "MuPDF")
// hits is [MuPDFRect] — draw highlight overlays over each rect
```

## Adding Annotations

```swift
let rect  = MuPDFRect(x: 72, y: 100, width: 200, height: 20)
let annot = try page.addAnnotation(type: .highlight, rect: rect)
annot.color = .highlightYellow
annot.update()
```

## Saving

```swift
try doc.save(to: "/path/to/output.pdf")
doc.close()
```
