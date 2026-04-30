# Types

Lightweight value types used throughout the MuPDF Mobile API.

## MuPDFRect

A rectangle in PDF user-space coordinates (points, where 1 pt = 1/72 inch). The origin `(x, y)` is the **top-left** corner.

### Declaration

```swift
// iOS
public struct MuPDFRect {
    public let x: Float
    public let y: Float
    public let width: Float
    public let height: Float
}
```

```kotlin
// Android
data class MuPDFRect(
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float
)
```

### Methods

| Method | Description |
|---|---|
| `inset(dx:dy:)` / `inset(dx, dy)` | Returns a new rect inset by `dx` horizontally and `dy` vertically |
| `contains(px:py:)` / `contains(px, py)` | Returns `true` if the point `(px, py)` is inside the rect |

---

## MuPDFColor

An RGBA colour with components in `[0.0, 1.0]`.

### Declaration

```swift
// iOS
public struct MuPDFColor {
    public let r: Float
    public let g: Float
    public let b: Float
    public let a: Float   // default 1.0 (fully opaque)
}
```

```kotlin
// Android
data class MuPDFColor(
    val r: Float,
    val g: Float,
    val b: Float,
    val a: Float = 1f
)
```

### Named Presets

| Preset | Value |
|---|---|
| `black` / `Black` | `(0, 0, 0, 1)` |
| `white` / `White` | `(1, 1, 1, 1)` |
| `highlightYellow` / `HighlightYellow` | `(1, 1, 0, 0.5)` |
| `highlightRed` / `HighlightRed` | `(1, 0, 0, 0.5)` |

### Android Helper

```kotlin
fun toArgbInt(): Int   // Packs the colour into an Android ARGB int
```

---

## MuPDFOutlineItem

A single node in the PDF's table of contents (outline / bookmarks tree).

### Declaration

```swift
// iOS
public final class MuPDFOutlineItem: NSObject {
    public let title: String
    public let pageIndex: Int          // zero-based, or -1 if not a page link
    public let children: [MuPDFOutlineItem]
}
```

```kotlin
// Android
data class MuPDFOutlineItem(
    val title: String,
    val pageIndex: Int,                     // zero-based, or -1 if not a page link
    val children: List<MuPDFOutlineItem> = emptyList()
)
```

Retrieve the outline via `MuPDFDocument.outline()`.

```swift
// iOS — recursive traversal
func printOutline(_ items: [MuPDFOutlineItem], indent: String = "") {
    for item in items {
        print("\(indent)\(item.title)  →  page \(item.pageIndex + 1)")
        printOutline(item.children, indent: indent + "  ")
    }
}
let outline = doc.outline()
printOutline(outline)
```

```kotlin
// Android — recursive traversal
fun printOutline(items: List<MuPDFOutlineItem>, indent: String = "") {
    for (item in items) {
        println("$indent${item.title}  →  page ${item.pageIndex + 1}")
        printOutline(item.children, "$indent  ")
    }
}
printOutline(doc.outline())
```
