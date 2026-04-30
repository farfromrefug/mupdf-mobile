# MuPDFEditor

High-level editing operations that operate on a whole document — inserting images and applying redactions.

## Creating an Editor

```swift
// iOS
let editor = MuPDFEditor(document: doc)
```

```kotlin
// Android
val editor = MuPDFEditor(doc)
```

## Inserting Images

Place a raster image on a specific page at a given rectangle:

### iOS

```swift
let imageData = try Data(contentsOf: imageURL)
let rect      = MuPDFRect(x: 72, y: 72, width: 200, height: 150)
try editor.insertImage(data: imageData, on: 0, rect: rect)
try doc.save(to: outputPath)
```

### Android

```kotlin
val imageBytes = File(imagePath).readBytes()
val rect       = MuPDFRect(72f, 72f, 200f, 150f)
editor.insertImage(imageBytes, pageIndex = 0, rect = rect)
doc.save(outputPath)
```

The image is embedded directly in the PDF. Supported formats are whatever the platform's image decoder supports (typically JPEG, PNG, GIF, BMP).

## Applying Redactions

Permanently burns the redaction marks into the page content:

### iOS

```swift
// 1. Add redaction marks to one or more pages
let mark = try page.addAnnotation(type: .redact, rect: sensitiveRect)
mark.update()

// 2. Burn them in and save
try editor.applyRedactions()
try doc.save(to: redactedPath)
```

### Android

```kotlin
// 1. Add redaction marks
val mark = page.addAnnotation(MuPDFAnnotationType.Redact, sensitiveRect)
mark.update()

// 2. Burn them in and save
editor.applyRedactions()
doc.save(redactedPath)
```

:::danger Irreversible
`applyRedactions()` permanently destroys the underlying text and images inside redaction rectangles. Always save to a new file path and keep the original intact until you have verified the output.
:::
