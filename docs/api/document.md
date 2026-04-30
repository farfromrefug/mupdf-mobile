# MuPDFDocument

The central class for working with PDF documents. Open from the file system or in-memory data, read properties, access pages, and edit document structure.

## Opening Documents

### `open(path:)` / `open(path)`

```swift
// iOS
public static func open(path: String) throws -> MuPDFDocument
```

```kotlin
// Android
@JvmStatic fun open(path: String): MuPDFDocument
```

Opens a document at the given absolute file-system path.

**Throws:**
- iOS: `MuPDFError.fileNotFound` if the path does not exist; `MuPDFError.invalidDocument` if parsing fails.
- Android: `MuPDFFileNotFoundException`; `MuPDFInvalidDocumentException`.

---

### `open(data:)` / `open(data)`

```swift
// iOS
public static func open(data: Data) throws -> MuPDFDocument
```

```kotlin
// Android
@JvmStatic fun open(data: ByteArray): MuPDFDocument
```

Opens a document from in-memory bytes. Useful when the PDF arrives over the network or is embedded in a bundle.

---

## Properties

| Property | iOS type | Android type | Description |
|---|---|---|---|
| `pageCount` | `Int` | `Int` | Total number of pages (0 if closed) |
| `title` | `String?` | `String?` | `info:Title` metadata, or `nil`/`null` |
| `author` | `String?` | `String?` | `info:Author` metadata, or `nil`/`null` |

---

## Page Access

### `loadPage(at:)` / `loadPage(index)`

```swift
// iOS
public func loadPage(at index: Int) throws -> MuPDFPage
```

```kotlin
// Android
open fun loadPage(index: Int): MuPDFPage
```

Loads the page at the given zero-based index and returns a ``MuPDFPage``.

**Throws:**
- `MuPDFError.documentClosed` / `MuPDFDocumentClosedException`
- `MuPDFError.pageIndexOutOfBounds` / `MuPDFPageOutOfBoundsException`

---

### `pageSize(at:)` / `pageSize(at)`

```swift
// iOS (CoreGraphics required)
public func pageSize(at index: Int) -> CGSize
```

```kotlin
// Android
open fun pageSize(at: Int): SizeF
```

Returns the page's dimensions in PDF points without loading the full page object. Useful for pre-computing layout before rendering.

---

## Saving

### `save(to:)` / `save(path)`

```swift
// iOS
public func save(to path: String) throws
```

```kotlin
// Android
open fun save(path: String)
```

Saves the document with any in-memory modifications to the specified path.

**Throws:** `MuPDFError.documentClosed` / `MuPDFDocumentClosedException`; `MuPDFError.saveFailed` / `MuPDFSaveException`.

:::warning
Always save to a **different** path from the source file. Overwriting the source while it is still open may corrupt the file.
:::

---

## Document Editing

### `merge(document:)` / `merge(document)`

```swift
// iOS
public func merge(document: MuPDFDocument) throws
```

```kotlin
// Android
open fun merge(document: MuPDFDocument)
```

Appends all pages from `document` to the end of this document.

---

### `insertBlankPage(at:width:height:)` / `insertBlankPage(index, width, height)`

```swift
// iOS
public func insertBlankPage(at index: Int, width: Float, height: Float) throws
```

```kotlin
// Android
open fun insertBlankPage(index: Int, width: Float, height: Float)
```

Inserts an empty page at `index` with the given dimensions (in PDF points).

---

### `deletePages(at:)` / `deletePages(indices)`

```swift
// iOS
public func deletePages(at indices: [Int]) throws
```

```kotlin
// Android
open fun deletePages(indices: List<Int>)
```

Deletes the pages at the given zero-based indices. Indices are processed in descending order to avoid shifting issues.

---

### `outline()`

```swift
// iOS
public func outline() -> [MuPDFOutlineItem]
```

```kotlin
// Android
open fun outline(): List<MuPDFOutlineItem>
```

Returns the document's table of contents as a tree of ``MuPDFOutlineItem`` nodes. Returns an empty array/list if the document has no outline or is closed.

---

## Lifecycle

### `close()`

```swift
// iOS
public func close()
```

```kotlin
// Android (also implements AutoCloseable)
override fun close()
```

Releases all native resources. Safe to call multiple times. The iOS deinit and Android finalizer also call `close()` as a safety net, but explicit cleanup is strongly recommended.

```kotlin
// Android — idiomatic usage with 'use'
MuPDFDocument.open(path).use { doc ->
    // …
}   // close() is called automatically
```
