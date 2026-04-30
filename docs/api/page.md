# MuPDFPage

Represents a single page of a PDF document. Obtained from `MuPDFDocument.loadPage`.

:::tip
`MuPDFPage` holds a reference back to its parent document. The document must not be closed while a page object is in use.
:::

## Properties

| Property | iOS type | Android type | Description |
|---|---|---|---|
| `index` | `Int` | `Int` | Zero-based page index |
| `width` | `Float` | `Float` | Page width in PDF points |
| `height` | `Float` | `Float` | Page height in PDF points |

---

## Rendering

### `render(scale:)` / `render(scale)`

```swift
// iOS
public func render(scale: Float) -> MuPDFBitmap
```

```kotlin
// Android
fun render(scale: Float): MuPDFBitmap
```

Renders the entire page at the given scale factor. A scale of `2.0` on a 595 × 842 pt A4 page produces a 1190 × 1684 px bitmap.

---

### `renderToSize(width:height:)` / `renderToSize(width, height)` *(via Renderer)*

```swift
// iOS — use MuPDFRenderer
public static func renderToSize(_ page: MuPDFPage, width: Int, height: Int) -> MuPDFBitmap
```

```kotlin
// Android
MuPDFRenderer.renderToSize(page, width, height)
```

Renders the page scaled to fit within the given pixel dimensions while preserving aspect ratio.

---

### `renderTile(rect:scale:)` / `renderTile(rect, scale)` *(via Renderer)*

```swift
// iOS — use MuPDFRenderer
public static func renderTile(_ page: MuPDFPage, rect: MuPDFRect, scale: Float) -> MuPDFBitmap
```

```kotlin
// Android
MuPDFRenderer.renderTile(page, rect, scale)
```

Renders only the specified sub-rectangle of the page. Use for tile-based rendering in scroll/zoom views.

---

## Text Search

### `search(text:)` / `search(text)`

```swift
// iOS
public func search(text: String) -> [MuPDFRect]
```

```kotlin
// Android
fun search(text: String): List<MuPDFRect>
```

Returns a list of ``MuPDFRect`` values indicating where `text` was found on the page. Returns an empty list if not found.

---

## Annotations

### `annotations()` 

```swift
// iOS
public func annotations() -> [MuPDFAnnotation]
```

```kotlin
// Android
fun annotations(): List<MuPDFAnnotation>
```

Returns all annotations currently on the page.

---

### `addAnnotation(type:rect:)` / `addAnnotation(type, rect)`

```swift
// iOS
public func addAnnotation(type: MuPDFAnnotationType, rect: MuPDFRect) throws -> MuPDFAnnotation
```

```kotlin
// Android
fun addAnnotation(type: MuPDFAnnotationType, rect: MuPDFRect): MuPDFAnnotation
```

Creates a new annotation of the given type at `rect` and returns it. Remember to set the desired colour and call `annot.update()`.

---

### `removeAnnotation(_:)` / `removeAnnotation(annotation)`

```swift
// iOS
public func removeAnnotation(_ annotation: MuPDFAnnotation) throws
```

```kotlin
// Android
fun removeAnnotation(annotation: MuPDFAnnotation)
```

Permanently removes the annotation from the page.
