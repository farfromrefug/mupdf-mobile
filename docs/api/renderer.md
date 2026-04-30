# MuPDFRenderer

A utility class providing convenience methods for scaled and tiled rendering that complement the core `MuPDFPage.render` API.

## Full-page Rendering

### `render(_:scale:)` / `render(page, scale)`

```swift
// iOS
public static func render(_ page: MuPDFPage, scale: Float) -> MuPDFBitmap
```

```kotlin
// Android
object MuPDFRenderer {
    @JvmStatic fun render(page: MuPDFPage, scale: Float): MuPDFBitmap
}
```

Renders the entire page at the given scale factor. Equivalent to calling `page.render(scale:)` directly.

---

### `renderToSize(_:width:height:)` / `renderToSize(page, width, height)`

```swift
// iOS
public static func renderToSize(_ page: MuPDFPage, width: Int, height: Int) -> MuPDFBitmap
```

```kotlin
// Android
@JvmStatic fun renderToSize(page: MuPDFPage, width: Int, height: Int): MuPDFBitmap
```

Renders the page scaled to fit the given pixel dimensions while preserving aspect ratio. Useful for thumbnails.

**Example — 300 px wide thumbnail:**

```swift
let thumb = MuPDFRenderer.renderToSize(page, width: 300, height: 400)
```

```kotlin
val thumb = MuPDFRenderer.renderToSize(page, width = 300, height = 400)
```

---

## Tiled Rendering

### `renderTile(_:rect:scale:)` / `renderTile(page, rect, scale)`

```swift
// iOS
public static func renderTile(_ page: MuPDFPage, rect: MuPDFRect, scale: Float) -> MuPDFBitmap
```

```kotlin
// Android
@JvmStatic fun renderTile(page: MuPDFPage, rect: MuPDFRect, scale: Float): MuPDFBitmap
```

Renders only the sub-rectangle `rect` of the page (coordinates in PDF points) at the given `scale`. The output bitmap covers exactly the requested tile.

**Tile calculation example:**

```swift
// iOS — divide an A4 page into a 3×4 grid of tiles
let tileW = page.width  / 3
let tileH = page.height / 4
for row in 0..<4 {
    for col in 0..<3 {
        let rect   = MuPDFRect(x: Float(col) * tileW, y: Float(row) * tileH,
                               width: tileW, height: tileH)
        let bitmap = MuPDFRenderer.renderTile(page, rect: rect, scale: 2.0)
        // cache bitmap…
    }
}
```

```kotlin
// Android
val tileW = page.width  / 3f
val tileH = page.height / 4f
for (row in 0 until 4) {
    for (col in 0 until 3) {
        val rect   = MuPDFRect(col * tileW, row * tileH, tileW, tileH)
        val bitmap = MuPDFRenderer.renderTile(page, rect, scale = 2f)
        // cache bitmap…
    }
}
```
