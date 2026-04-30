# Rendering Pages

MuPDF Mobile renders PDF pages to platform-native bitmaps (`UIImage` on iOS, `Bitmap` on Android) with fine-grained control over resolution and region.

## Basic Rendering

### iOS

```swift
let page   = try doc.loadPage(at: 0)
let bitmap = page.render(scale: 2.0)   // 2× Retina
imageView.image = bitmap.image
```

### Android

```kotlin
val page   = doc.loadPage(0)
val bitmap = page.render(2f)           // 2× density
imageView.setImageBitmap(bitmap.bitmap)
```

The `scale` parameter is a multiplier applied to the page's native PDF point dimensions (1 point = 1/72 inch). A scale of `UIScreen.main.scale` / `displayMetrics.density` renders at the device's native resolution.

## Render to Fixed Pixel Dimensions

If you need a fixed pixel output (e.g., a 300 × 400 thumbnail), use `renderToSize`:

### iOS

```swift
let bitmap = page.renderToSize(width: 300, height: 400)
```

### Android

```kotlin
val bitmap = MuPDFRenderer.renderToSize(page, width = 300, height = 400)
```

MuPDF computes the scale factor automatically so the page fits within the requested bounds while preserving its aspect ratio.

## Tiled Rendering

For large documents displayed inside a scroll/zoom view, rendering the entire page at high resolution is wasteful. Instead, render only the tile that is currently visible.

### iOS — UICollectionView tile cache

```swift
let tileRect = MuPDFRect(x: tileX, y: tileY, width: tileW, height: tileH)
let bitmap   = page.renderTile(rect: tileRect, scale: 3.0)
cell.imageView.image = bitmap.image
```

### Android — RecyclerView tile adapter

```kotlin
val tileRect = MuPDFRect(tileX, tileY, tileW, tileH)
val bitmap   = MuPDFRenderer.renderTile(page, tileRect, scale = 3f)
holder.imageView.setImageBitmap(bitmap.bitmap)
```

:::tip Memory guidance
For typical A4 pages at 2× scale the rendered bitmap is ~2 MB. At 4× it is ~8 MB. Use tiled rendering when displaying pages at high zoom levels to keep your app's memory footprint under control.
:::

## Page Dimensions

You can read the page's native dimensions (in PDF points) before rendering:

### iOS

```swift
let page = try doc.loadPage(at: 0)
print("Width: \(page.width) pt, Height: \(page.height) pt")

// Without loading the full page object:
let size = doc.pageSize(at: 0)   // CGSize
```

### Android

```kotlin
val page = doc.loadPage(0)
println("Width: ${page.width} pt, Height: ${page.height} pt")

val size = doc.pageSize(at = 0)  // SizeF
```

## Background Rendering

Rendering is synchronous and CPU-intensive. Always dispatch to a background thread:

### iOS

```swift
Task.detached(priority: .userInitiated) {
    let bitmap = page.render(scale: 2.0)
    await MainActor.run { imageView.image = bitmap.image }
}
```

### Android

```kotlin
lifecycleScope.launch(Dispatchers.IO) {
    val bitmap = page.render(2f)
    withContext(Dispatchers.Main) {
        imageView.setImageBitmap(bitmap.bitmap)
    }
}
```

## CollectionView / RecyclerView Integration

A typical pattern for smooth scrolling is to cancel the previous render job when a cell is recycled:

### iOS — cancel on prepareForReuse

```swift
private var renderTask: Task<Void, Never>?

override func prepareForReuse() {
    super.prepareForReuse()
    renderTask?.cancel()
    imageView.image = nil
}

func configure(pageIndex: Int, document: MuPDFDocument) {
    renderTask = Task {
        let bitmap: MuPDFBitmap? = await Task.detached(priority: .userInitiated) {
            guard let page = try? document.loadPage(at: pageIndex) else { return nil }
            return page.render(scale: 0.3)
        }.value
        guard !Task.isCancelled else { return }
        await MainActor.run { imageView.image = bitmap?.image }
    }
}
```

### Android — cancel coroutine on recycle

```kotlin
var renderJob: Job? = null

// In onViewRecycled:
renderJob?.cancel()
imageView.setImageBitmap(null)

// In onBindViewHolder:
renderJob = scope.launch {
    val bitmap = withContext(Dispatchers.IO) {
        runCatching { MuPDFRenderer.render(page, 0.3f) }.getOrNull()
    }
    imageView.setImageBitmap(bitmap?.bitmap)
}
```
