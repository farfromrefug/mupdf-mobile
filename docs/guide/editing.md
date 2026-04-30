# Document Editing

MuPDF Mobile provides a set of editing primitives for manipulating PDF document structure and content.

## Merging Documents

Append all pages from a source document onto another:

### iOS

```swift
let base   = try MuPDFDocument.open(path: "/path/base.pdf")
let extra  = try MuPDFDocument.open(path: "/path/extra.pdf")

try base.merge(document: extra)
try base.save(to: "/path/merged.pdf")

base.close()
extra.close()
```

### Android

```kotlin
val base  = MuPDFDocument.open("/path/base.pdf")
val extra = MuPDFDocument.open("/path/extra.pdf")

base.merge(extra)
base.save("/path/merged.pdf")

base.close()
extra.close()
```

## Deleting Pages

Remove one or more pages by their zero-based index:

### iOS

```swift
// Delete pages 3 and 5 (zero-based)
try doc.deletePages(at: [3, 5])
try doc.save(to: outputPath)
```

### Android

```kotlin
doc.deletePages(listOf(3, 5))
doc.save(outputPath)
```

Indices are processed in descending order internally so that earlier deletions don't shift subsequent indices.

## Inserting Blank Pages

Add an empty page at a specific position:

### iOS

```swift
// Insert an A4 blank page at index 2
try doc.insertBlankPage(at: 2, width: 595, height: 842)
```

### Android

```kotlin
doc.insertBlankPage(index = 2, width = 595f, height = 842f)
```

Standard page sizes in PDF points (1 pt = 1/72 inch):

| Format | Width | Height |
|---|---|---|
| A4 portrait | 595 | 842 |
| Letter portrait | 612 | 792 |
| A3 portrait | 842 | 1190 |

## Inserting Images

Use `MuPDFEditor` to embed a raster image on a page:

### iOS

```swift
let editor = MuPDFEditor(document: doc)
let imageRect = MuPDFRect(x: 72, y: 72, width: 200, height: 150)
try editor.insertImage(data: imageData, on: 0, rect: imageRect)
try doc.save(to: outputPath)
```

### Android

```kotlin
val editor    = MuPDFEditor(doc)
val imageRect = MuPDFRect(72f, 72f, 200f, 150f)
editor.insertImage(imageBytes, pageIndex = 0, rect = imageRect)
doc.save(outputPath)
```

## Applying Redactions

See [Annotations → Redactions](/guide/annotations#redactions) for the full workflow.

```swift
// iOS — quick reference
let editor = MuPDFEditor(document: doc)
try editor.applyRedactions()
try doc.save(to: redactedPath)
```

```kotlin
// Android — quick reference
val editor = MuPDFEditor(doc)
editor.applyRedactions()
doc.save(redactedPath)
```

:::warning Save to a new path
Always save to a different path than the source when editing, to avoid corrupting the original file if an error occurs mid-write.
:::

## Saving Documents

Call `save` after any editing operation to persist changes:

### iOS

```swift
try doc.save(to: "/path/to/output.pdf")
```

### Android

```kotlin
doc.save("/path/to/output.pdf")
```

Attempting to save a closed document throws `MuPDFError.documentClosed` (iOS) or `MuPDFDocumentClosedException` (Android).
