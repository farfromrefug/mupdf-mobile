# MuPDFAnnotation / MuPDFAnnotationType

## MuPDFAnnotation

An annotation attached to a specific PDF page. Obtained from `page.annotations()` or `page.addAnnotation(…)`.

### Properties

| Property | iOS type | Android type | Description |
|---|---|---|---|
| `type` | `MuPDFAnnotationType` | `MuPDFAnnotationType` | The annotation's type |
| `rect` | `MuPDFRect` | `MuPDFRect` | Bounding rectangle in page coordinates |
| `color` | `MuPDFColor` | `MuPDFColor` | Fill / stroke colour |
| `contents` | `String` | `String` | Note / comment text |

### Methods

#### `update()`

```swift
// iOS
public func update()
```

```kotlin
// Android
fun update()
```

Commits any property changes to the PDF. **Must** be called after modifying `color`, `contents`, or other properties.

---

## MuPDFAnnotationType

An enum of all supported PDF annotation types.

### Cases

| Case (iOS) | Case (Android) | `pdfAnnotValue` | Description |
|---|---|---|---|
| `.text` | `Text` | 0 | Sticky-note / comment bubble |
| `.link` | `Link` | 1 | Hyperlink region |
| `.freeText` | `FreeText` | 2 | Editable text drawn on page |
| `.line` | `Line` | 3 | Straight line |
| `.square` | `Square` | 4 | Rectangle / box |
| `.circle` | `Circle` | 5 | Ellipse / circle |
| `.ink` | `Ink` | 14 | Free-hand ink drawing |
| `.highlight` | `Highlight` | 15 | Highlight over text |
| `.underline` | `Underline` | 16 | Underline beneath text |
| `.squiggly` | `Squiggly` | 17 | Wavy underline |
| `.strikeout` | `StrikeOut` | 18 | Line through text |
| `.stamp` | `Stamp` | 20 | Approval stamp |
| `.redact` | `Redact` | 24 | Redaction mark |

### Properties (iOS)

```swift
var name: String        // Human-readable label, e.g. "Highlight"
var pdfAnnotValue: Int  // Integer value from the PDF spec
```

### Properties (Android)

```kotlin
val displayName: String   // Human-readable label, e.g. "Highlight"
val pdfAnnotValue: Int    // Integer value from the PDF spec
```

### Factory Method (Android)

```kotlin
companion object {
    fun fromPdfAnnotValue(value: Int): MuPDFAnnotationType?
}
```

Returns the matching type for a raw integer value, or `null` if not recognised.
