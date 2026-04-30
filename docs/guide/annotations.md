# Annotations

MuPDF Mobile supports **13 annotation types** that can be added, edited, and removed on any page of a PDF document.

## Supported Types

| Type | iOS enum | Android enum | Description |
|---|---|---|---|
| Text note | `.text` | `Text` | Sticky-note / comment bubble |
| Highlight | `.highlight` | `Highlight` | Yellow (or custom) highlight over text |
| Underline | `.underline` | `Underline` | Underline beneath text |
| Squiggly | `.squiggly` | `Squiggly` | Wavy underline |
| Strikeout | `.strikeout` | `StrikeOut` | Line through text |
| Free text | `.freeText` | `FreeText` | Editable text drawn on page |
| Ink | `.ink` | `Ink` | Free-hand drawing |
| Line | `.line` | `Line` | Straight line |
| Square | `.square` | `Square` | Rectangle/box |
| Circle | `.circle` | `Circle` | Ellipse/circle |
| Stamp | `.stamp` | `Stamp` | Approval stamp |
| Link | `.link` | `Link` | Hyperlink region |
| Redact | `.redact` | `Redact` | Redaction mark (apply with Editor) |

## Listing Annotations

### iOS

```swift
let page  = try doc.loadPage(at: 0)
let annots = page.annotations()

for annot in annots {
    print("\(annot.type.name)  rect: \(annot.rect)  note: \(annot.contents)")
}
```

### Android

```kotlin
val page   = doc.loadPage(0)
val annots = page.annotations()

annots.forEach { annot ->
    println("${annot.type.displayName}  rect: ${annot.rect}  note: ${annot.contents}")
}
```

## Adding Annotations

### iOS

```swift
let rect  = MuPDFRect(x: 72, y: 100, width: 200, height: 20)
let annot = try page.addAnnotation(type: .highlight, rect: rect)

// Set colour (semi-transparent yellow)
annot.color = MuPDFColor(r: 1, g: 1, b: 0, a: 0.5)
// Optionally attach a note
annot.contents = "Important passage"
// Commit the changes
annot.update()
```

### Android

```kotlin
val rect  = MuPDFRect(72f, 100f, 200f, 20f)
val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, rect)

annot.color    = MuPDFColor(1f, 1f, 0f, 0.5f)
annot.contents = "Important passage"
annot.update()
```

:::tip Always call update()
Changes to `color`, `contents`, or geometry are not persisted until you call `annot.update()`.
:::

## Editing Annotations

You can modify an existing annotation's properties at any time:

```swift
// iOS
annot.contents = "Updated note text"
annot.color    = MuPDFColor(r: 1, g: 0, b: 0, a: 0.5)   // red
annot.update()
```

```kotlin
// Android
annot.contents = "Updated note text"
annot.color    = MuPDFColor(1f, 0f, 0f, 0.5f)   // red
annot.update()
```

## Removing Annotations

### iOS

```swift
try page.removeAnnotation(annot)
```

### Android

```kotlin
page.removeAnnotation(annot)
```

## Colours

`MuPDFColor` uses normalised RGBA floats in the range `[0, 1]`. Several named presets are available:

| Preset | iOS | Android |
|---|---|---|
| Black | `MuPDFColor.black` | `MuPDFColor.Black` |
| White | `MuPDFColor.white` | `MuPDFColor.White` |
| Highlight yellow | `MuPDFColor.highlightYellow` | `MuPDFColor.HighlightYellow` |
| Highlight red | `MuPDFColor.highlightRed` | `MuPDFColor.HighlightRed` |

## Redactions

Redact marks are added like any other annotation, but the content is only permanently removed when you call `MuPDFEditor.applyRedactions`:

```swift
// iOS
let mark = try page.addAnnotation(type: .redact, rect: rect)
mark.update()

let editor = MuPDFEditor(document: doc)
try editor.applyRedactions()
try doc.save(to: outputPath)
```

```kotlin
// Android
val mark = page.addAnnotation(MuPDFAnnotationType.Redact, rect)
mark.update()

val editor = MuPDFEditor(doc)
editor.applyRedactions()
doc.save(outputPath)
```

:::warning Redaction is permanent
Once `applyRedactions()` has been called and the document is saved, the redacted content cannot be recovered.
:::
