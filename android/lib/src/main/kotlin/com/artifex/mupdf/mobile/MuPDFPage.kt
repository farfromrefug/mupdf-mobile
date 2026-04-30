package com.artifex.mupdf.mobile

import android.graphics.Bitmap

/**
 * Represents a single page within a [MuPDFDocument].
 *
 * Pages are loaded on demand via [MuPDFDocument.loadPage] and internally hold
 * a native `fz_page` pointer. Release native resources by calling [close] or
 * by closing the parent document.
 *
 * **Thread safety:** Not thread-safe. All calls must be made from the same
 * thread or serialised externally.
 */
open class MuPDFPage internal constructor(
    /** Zero-based index of this page within its parent document. */
    val index: Int,
    /** Width of the page in PDF points (1 pt = 1/72 inch). */
    val width: Float,
    /** Height of the page in PDF points. */
    val height: Float,
    /** Opaque pointer to the native `PageHandle`. */
    internal var nativeHandle: Long
) : AutoCloseable {

    private var closed = false

    // ─────────────────────────────────────────────────────────────────────────
    // Rendering
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Renders the page at the given scale factor.
     *
     * @param scale Scale factor relative to PDF points (e.g. 2f for a 2×
     *   high-density render).
     * @return A [MuPDFBitmap] with dimensions `(width × scale, height × scale)`.
     */
    open fun render(scale: Float): MuPDFBitmap {
        val pw = (width  * scale).toInt().coerceAtLeast(1)
        val ph = (height * scale).toInt().coerceAtLeast(1)
        return render(pw, ph)
    }

    /**
     * Renders the page at the specified pixel dimensions.
     *
     * @param width  Output bitmap width in pixels.
     * @param height Output bitmap height in pixels.
     * @return A [MuPDFBitmap] of the requested size.
     */
    open fun render(width: Int, height: Int): MuPDFBitmap {
        checkNotClosed()
        require(width > 0 && height > 0) { "Dimensions must be positive" }
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        if (nativeHandle != -1L) {
            nativeRender(nativeHandle, bmp, width.toFloat() / this.width, 0, 0, width, height)
        } else {
            bmp.eraseColor(android.graphics.Color.WHITE)
        }
        return MuPDFBitmap(bmp)
    }

    /**
     * Renders a sub-tile of the page.
     *
     * Tile coordinates are in the scaled pixel-space of the fully-rendered page.
     *
     * @param x          Left edge of the tile in scaled pixels.
     * @param y          Top edge of the tile in scaled pixels.
     * @param tileWidth  Tile width in pixels.
     * @param tileHeight Tile height in pixels.
     * @param scale      Scale factor for the virtual full-page coordinate space.
     * @return A [MuPDFBitmap] containing just the requested tile.
     */
    open fun renderTile(x: Int, y: Int, tileWidth: Int, tileHeight: Int, scale: Float): MuPDFBitmap {
        checkNotClosed()
        require(tileWidth > 0 && tileHeight > 0) { "Tile dimensions must be positive" }
        val bmp = Bitmap.createBitmap(tileWidth, tileHeight, Bitmap.Config.ARGB_8888)
        if (nativeHandle != -1L) {
            nativeRender(nativeHandle, bmp, scale, x, y, tileWidth, tileHeight)
        } else {
            bmp.eraseColor(android.graphics.Color.WHITE)
        }
        return MuPDFBitmap(bmp)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Annotations
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns all annotations on this page.
     */
    open fun annotations(): List<MuPDFAnnotation> {
        checkNotClosed()
        if (nativeHandle == -1L) return emptyList()
        val handles = nativeGetAnnotations(nativeHandle)
        return handles.map { handle ->
            val typeVal = MuPDFAnnotation.nativeGetAnnotationType(handle)
            val type = MuPDFAnnotationType.fromPdfAnnotValue(typeVal) ?: MuPDFAnnotationType.Text
            val rectArr = MuPDFAnnotation.nativeGetAnnotationRect(handle)
            val rect = MuPDFRect(rectArr[0], rectArr[1],
                                 rectArr[2] - rectArr[0], rectArr[3] - rectArr[1])
            val colorArr = MuPDFAnnotation.nativeGetAnnotationColor(handle)
            val color = MuPDFColor(colorArr[0], colorArr[1], colorArr[2], colorArr[3])
            val contents = MuPDFAnnotation.nativeGetAnnotationContents(handle) ?: ""
            MuPDFAnnotation(type, rect, color, colorArr[3], contents, handle, this)
        }
    }

    /**
     * Adds a new annotation of the specified type and returns it.
     *
     * @param type The annotation type.
     * @param rect Bounding rectangle in PDF user-space points.
     * @return The newly created [MuPDFAnnotation].
     * @throws MuPDFAnnotationException if the annotation cannot be created.
     */
    @Throws(MuPDFAnnotationException::class)
    open fun addAnnotation(type: MuPDFAnnotationType, rect: MuPDFRect): MuPDFAnnotation {
        checkNotClosed()
        val handle = nativeAddAnnotation(nativeHandle, type.pdfAnnotValue,
                                         rect.x, rect.y,
                                         rect.x + rect.width, rect.y + rect.height)
        if (handle == -1L) throw MuPDFAnnotationException("Failed to add annotation")
        return MuPDFAnnotation(type, rect, nativeHandle = handle, page = this)
    }

    /**
     * Removes an annotation from this page.
     *
     * @param annotation The annotation to remove.
     * @throws MuPDFAnnotationException if removal fails.
     */
    @Throws(MuPDFAnnotationException::class)
    open fun removeAnnotation(annotation: MuPDFAnnotation) {
        checkNotClosed()
        if (nativeHandle == -1L || annotation.nativeHandle == -1L) return
        if (!nativeRemoveAnnotation(nativeHandle, annotation.nativeHandle)) {
            throw MuPDFAnnotationException("Failed to remove annotation")
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Text
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Searches the page for all occurrences of [text] (case-insensitive).
     *
     * @return A list of [MuPDFRect] values, one per search-result quad.
     */
    open fun search(text: String): List<MuPDFRect> {
        checkNotClosed()
        if (text.isEmpty() || nativeHandle == -1L) return emptyList()
        val floats = nativeSearch(nativeHandle, text)
        val result = mutableListOf<MuPDFRect>()
        var i = 0
        while (i + 3 < floats.size) {
            result.add(MuPDFRect(floats[i], floats[i + 1],
                                 floats[i + 2] - floats[i], floats[i + 3] - floats[i + 1]))
            i += 4
        }
        return result
    }

    /**
     * Extracts all text content from this page as a plain string.
     */
    open val textContent: String
        get() {
            checkNotClosed()
            if (nativeHandle == -1L) return ""
            return nativeGetTextContent(nativeHandle) ?: ""
        }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    /** Releases the underlying native page object. Safe to call multiple times. */
    override fun close() {
        if (closed) return
        closed = true
        if (nativeHandle != -1L) {
            nativeClosePage(nativeHandle)
            nativeHandle = -1L
        }
    }

    private fun checkNotClosed() {
        if (closed) throw MuPDFDocumentClosedException()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // JNI bridge
    // ─────────────────────────────────────────────────────────────────────────

    private companion object {
        @JvmStatic private external fun nativeRender(
            pageHandle: Long, bitmap: Bitmap,
            scale: Float, x: Int, y: Int, width: Int, height: Int
        )

        @JvmStatic private external fun nativeGetAnnotations(pageHandle: Long): LongArray
        @JvmStatic private external fun nativeAddAnnotation(
            pageHandle: Long, type: Int,
            x0: Float, y0: Float, x1: Float, y1: Float
        ): Long
        @JvmStatic private external fun nativeRemoveAnnotation(pageHandle: Long, annotHandle: Long): Boolean
        @JvmStatic private external fun nativeSearch(pageHandle: Long, text: String): FloatArray
        @JvmStatic private external fun nativeGetTextContent(pageHandle: Long): String?
        @JvmStatic private external fun nativeClosePage(pageHandle: Long)
    }
}
