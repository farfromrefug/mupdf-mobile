package com.example.mupdfmobile.demo

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.util.LruCache
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import com.artifex.mupdf.mobile.MuPDFPage
import com.artifex.mupdf.mobile.MuPDFRenderer
import kotlinx.coroutines.*

/**
 * A custom [View] that renders a [MuPDFPage] using tiled rendering.
 *
 * Instead of rendering the entire page into one large bitmap (which would be
 * blurry when zoomed in), the view renders the page in small tiles, each at
 * the current zoom level.  Only the tiles that are currently visible are
 * rendered, and they are cached so they are not re-rendered unnecessarily.
 *
 * **Usage**:
 * ```kotlin
 * val view = TiledPDFView(context)
 * view.setPage(page)          // call from any thread; invalidates the view
 * ```
 *
 * The view handles pinch-to-zoom and scroll gestures out-of-the-box.
 */
class TiledPDFView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    // ─────────────────────────────────────────────────────────────────────────
    // Configuration
    // ─────────────────────────────────────────────────────────────────────────

    /** Size (in pixels) of each rendered tile. Smaller = less memory; larger = fewer tiles. */
    private val tileSize: Int = MuPDFRenderer.RECOMMENDED_TILE_SIZE

    /** Minimum zoom factor (0.5 = half size). */
    private val minZoom = 0.5f

    /** Maximum zoom factor (8× = 8× screen pixels per PDF point). */
    private val maxZoom = 8.0f

    // ─────────────────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────────────────

    private var page: MuPDFPage? = null

    /** Current zoom factor (1.0 = page fills view width). */
    private var zoom = 1.0f

    /** Scroll offset in *virtual* (scaled) pixels. */
    private var scrollX2 = 0f
    private var scrollY2 = 0f

    /** Coroutine scope for tile rendering jobs. */
    private val renderScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    /** Tile cache keyed by "$col-$row-$zoomKey" where zoomKey = (zoom*100).toInt(). */
    private val tileCache: LruCache<String, Bitmap> = LruCache(
        /* maxSize = */ (Runtime.getRuntime().maxMemory() / 1024 / 8).toInt()
    ) { _, bmp -> bmp.byteCount / 1024 }

    /** Set of tile keys currently being rendered (to avoid duplicate jobs). */
    private val pendingTiles = mutableSetOf<String>()

    // Paint for placeholder background
    private val placeholderPaint = Paint().apply { color = Color.LTGRAY }
    private val borderPaint = Paint().apply {
        color = Color.DKGRAY
        style = Paint.Style.STROKE
        strokeWidth = 1f
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Gesture detectors
    // ─────────────────────────────────────────────────────────────────────────

    private val scaleDetector = ScaleGestureDetector(
        context,
        object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                val newZoom = (zoom * detector.scaleFactor).coerceIn(minZoom, maxZoom)
                if (newZoom != zoom) {
                    // Scale scroll offset around the focal point
                    val focusX = detector.focusX + scrollX2
                    val focusY = detector.focusY + scrollY2
                    scrollX2 = focusX - detector.focusX * (newZoom / zoom)
                    scrollY2 = focusY - detector.focusY * (newZoom / zoom)
                    zoom = newZoom
                    clampScroll()
                    invalidate()
                }
                return true
            }
        }
    )

    private val gestureDetector = GestureDetector(
        context,
        object : GestureDetector.SimpleOnGestureListener() {
            override fun onScroll(
                e1: MotionEvent?,
                e2: MotionEvent,
                distanceX: Float,
                distanceY: Float
            ): Boolean {
                scrollX2 += distanceX
                scrollY2 += distanceY
                clampScroll()
                invalidate()
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                // Double-tap: cycle through zoom levels
                val targetZoom = when {
                    zoom < 1.5f -> 2.0f
                    zoom < 3.0f -> 4.0f
                    else        -> 1.0f
                }
                animateZoom(targetZoom, e.x, e.y)
                return true
            }
        }
    )

    // ─────────────────────────────────────────────────────────────────────────
    // Public API
    // ─────────────────────────────────────────────────────────────────────────

    /** Attaches a [MuPDFPage] to this view. Safe to call from any thread. */
    fun setPage(p: MuPDFPage?) {
        page = p
        zoom = 1.0f
        scrollX2 = 0f
        scrollY2 = 0f
        clearCache()
        post { invalidate() }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Touch handling
    // ─────────────────────────────────────────────────────────────────────────

    override fun onTouchEvent(event: MotionEvent): Boolean {
        scaleDetector.onTouchEvent(event)
        gestureDetector.onTouchEvent(event)
        performClick()
        return true
    }

    override fun performClick(): Boolean {
        super.performClick()
        return true
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Drawing
    // ─────────────────────────────────────────────────────────────────────────

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val p = page ?: return

        // Compute base scale: at zoom=1, page width == view width
        val baseScale = if (p.width > 0) width.toFloat() / p.width else 1f
        val scale = baseScale * zoom

        // Total scaled page size
        val scaledPageW = (p.width * scale).toInt()
        val scaledPageH = (p.height * scale).toInt()

        // Viewport rect in scaled space (what's visible on screen)
        val vpLeft   = scrollX2.toInt()
        val vpTop    = scrollY2.toInt()
        val vpRight  = vpLeft + width
        val vpBottom = vpTop + height

        // Zoom key — changes when zoom changes significantly (0.01 granularity)
        val zoomKey = (zoom * 100).toInt()

        // Iterate over tiles that intersect the viewport
        val colStart = (vpLeft / tileSize).coerceAtLeast(0)
        val rowStart = (vpTop  / tileSize).coerceAtLeast(0)
        val colEnd   = ((vpRight  + tileSize - 1) / tileSize).coerceAtMost((scaledPageW + tileSize - 1) / tileSize)
        val rowEnd   = ((vpBottom + tileSize - 1) / tileSize).coerceAtMost((scaledPageH + tileSize - 1) / tileSize)

        for (row in rowStart until rowEnd) {
            for (col in colStart until colEnd) {
                val tx = col * tileSize
                val ty = row * tileSize
                val tw = tileSize.coerceAtMost(scaledPageW - tx)
                val th = tileSize.coerceAtMost(scaledPageH - ty)
                if (tw <= 0 || th <= 0) continue

                val key = "$col-$row-$zoomKey"
                val bmp = tileCache.get(key)

                // Destination rect on screen
                val destLeft   = tx - scrollX2
                val destTop    = ty - scrollY2
                val destRight  = destLeft + tw
                val destBottom = destTop  + th
                val destRect   = RectF(destLeft, destTop, destRight, destBottom)

                if (bmp != null && !bmp.isRecycled) {
                    canvas.drawBitmap(bmp, null, destRect, null)
                } else {
                    // Placeholder
                    canvas.drawRect(destRect, placeholderPaint)
                    canvas.drawRect(destRect, borderPaint)
                    // Schedule async render
                    scheduleTile(p, key, tx, ty, tw, th, scale, zoomKey)
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Tile scheduling
    // ─────────────────────────────────────────────────────────────────────────

    private fun scheduleTile(
        p: MuPDFPage,
        key: String,
        tx: Int, ty: Int, tw: Int, th: Int,
        scale: Float,
        zoomKey: Int
    ) {
        synchronized(pendingTiles) {
            if (pendingTiles.contains(key)) return
            pendingTiles.add(key)
        }

        renderScope.launch {
            try {
                val muBmp = p.renderTile(tx, ty, tw, th, scale)
                tileCache.put(key, muBmp.bitmap)
                // Purge stale tiles for other zoom levels to free memory
                evictZoom(zoomKey)
                withContext(Dispatchers.Main) { invalidate() }
            } catch (_: Exception) {
                // ignore cancelled / closed page
            } finally {
                synchronized(pendingTiles) { pendingTiles.remove(key) }
            }
        }
    }

    private fun evictZoom(currentZoomKey: Int) {
        // Remove all cached tiles whose zoom key differs from current
        val snapshot = tileCache.snapshot()
        for ((k, _) in snapshot) {
            val parts = k.split("-")
            if (parts.size == 3 && parts[2].toIntOrNull() != currentZoomKey) {
                tileCache.remove(k)
            }
        }
    }

    private fun clearCache() {
        tileCache.evictAll()
        synchronized(pendingTiles) { pendingTiles.clear() }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Scroll clamping
    // ─────────────────────────────────────────────────────────────────────────

    private fun clampScroll() {
        val p = page ?: return
        val baseScale = if (p.width > 0) width.toFloat() / p.width else 1f
        val scale = baseScale * zoom
        val scaledW = (p.width  * scale).toInt()
        val scaledH = (p.height * scale).toInt()
        scrollX2 = scrollX2.coerceIn(0f, (scaledW - width).coerceAtLeast(0).toFloat())
        scrollY2 = scrollY2.coerceIn(0f, (scaledH - height).coerceAtLeast(0).toFloat())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Double-tap zoom animation (simple linear interpolation over 8 frames)
    // ─────────────────────────────────────────────────────────────────────────

    private fun animateZoom(targetZoom: Float, focusX: Float, focusY: Float) {
        val startZoom   = zoom
        val steps       = 8
        var step        = 0
        val handler     = android.os.Handler(android.os.Looper.getMainLooper())

        fun tick() {
            step++
            val t = step.toFloat() / steps
            val newZoom = startZoom + (targetZoom - startZoom) * t
            val ratio = newZoom / zoom
            scrollX2 = (focusX + scrollX2) - focusX * ratio
            scrollY2 = (focusY + scrollY2) - focusY * ratio
            zoom = newZoom
            clampScroll()
            invalidate()
            if (step < steps) handler.postDelayed(::tick, 16)
        }

        clearCache()
        handler.post(::tick)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        renderScope.cancel()
        clearCache()
    }
}
