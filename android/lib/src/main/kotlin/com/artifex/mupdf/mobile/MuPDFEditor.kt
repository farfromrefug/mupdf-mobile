package com.artifex.mupdf.mobile

/**
 * Provides document-level editing operations such as image insertion and
 * redaction.
 *
 * An [MuPDFEditor] is always bound to a specific [MuPDFDocument]. Changes
 * are held in memory until [MuPDFDocument.save] is called.
 *
 * ## Example
 * ```kotlin
 * val editor = MuPDFEditor(doc)
 * val page = doc.loadPage(0)
 *
 * // Insert a watermark image
 * val imageBytes = assets.open("watermark.png").readBytes()
 * editor.insertImage(page, imageBytes, MuPDFRect(400f, 600f, 150f, 60f))
 *
 * // Redact sensitive text
 * editor.redact(page, MuPDFRect(50f, 100f, 200f, 20f))
 * editor.applyRedactions()
 *
 * doc.save("/sdcard/output.pdf")
 * ```
 *
 * @property document The document this editor is bound to.
 */
open class MuPDFEditor(val document: MuPDFDocument) {

    // ─────────────────────────────────────────────────────────────────────────
    // Image insertion
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Inserts an image onto a page at the specified rectangle.
     *
     * Supported image formats: JPEG, PNG, and any format decodable by MuPDF.
     *
     * @param page  The target page.
     * @param image Raw image bytes (JPEG / PNG / …).
     * @param rect  Bounding rectangle in PDF user-space points where the image
     *              will be placed.
     * @throws MuPDFDocumentClosedException if the document is closed.
     * @throws MuPDFEngineException         if the image cannot be inserted.
     */
    @Throws(MuPDFDocumentClosedException::class, MuPDFEngineException::class)
    open fun insertImage(page: MuPDFPage, image: ByteArray, rect: MuPDFRect) {
        require(image.isNotEmpty()) { "image bytes must not be empty" }
        val ok = nativeInsertImage(document.nativeHandle, page.nativeHandle,
                                   image, rect.x, rect.y,
                                   rect.x + rect.width, rect.y + rect.height)
        if (!ok) throw MuPDFEngineException("insertImage failed")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Redaction
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Marks a rectangular region on a page for redaction.
     *
     * The region is visually covered but the underlying content is not
     * permanently removed until [applyRedactions] is called.
     *
     * @param page The page containing the content to redact.
     * @param rect Rectangle to redact in PDF user-space points.
     * @throws MuPDFDocumentClosedException if the document is closed.
     */
    @Throws(MuPDFDocumentClosedException::class, MuPDFAnnotationException::class)
    open fun redact(page: MuPDFPage, rect: MuPDFRect) {
        page.addAnnotation(MuPDFAnnotationType.Redact, rect)
    }

    /**
     * Permanently removes all content covered by redaction annotations.
     *
     * ⚠️ **This operation is irreversible.** Save a backup before calling.
     *
     * @throws MuPDFDocumentClosedException if the document is closed.
     * @throws MuPDFEngineException         if redaction fails.
     */
    @Throws(MuPDFDocumentClosedException::class, MuPDFEngineException::class)
    open fun applyRedactions() {
        val ok = nativeApplyRedactions(document.nativeHandle)
        if (!ok) throw MuPDFEngineException("applyRedactions failed")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // JNI bridge
    // ─────────────────────────────────────────────────────────────────────────

    private companion object {
        @JvmStatic private external fun nativeInsertImage(
            docHandle: Long, pageHandle: Long,
            imageBytes: ByteArray,
            x0: Float, y0: Float, x1: Float, y1: Float
        ): Boolean

        @JvmStatic private external fun nativeApplyRedactions(docHandle: Long): Boolean
    }
}
