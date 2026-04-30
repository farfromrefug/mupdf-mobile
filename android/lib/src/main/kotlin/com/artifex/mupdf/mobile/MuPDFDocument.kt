package com.artifex.mupdf.mobile

import android.util.SizeF
import java.io.File

/**
 * A PDF (or XPS / CBZ / EPUB) document managed by the MuPDF engine.
 *
 * ## Thread safety
 * `MuPDFDocument` is **not** thread-safe. Serialise all calls externally when
 * using multiple threads.
 *
 * ## Memory management
 * Always call [close] (or use Kotlin's `use` block) when finished. The JVM
 * finaliser also closes the document, but relying on GC for native resource
 * release is discouraged.
 *
 * ## Example
 * ```kotlin
 * MuPDFDocument.open("/sdcard/sample.pdf").use { doc ->
 *     println("Pages: ${doc.pageCount}")
 *     val page = doc.loadPage(0)
 *     val bitmap = page.render(2f)
 *     imageView.setImageBitmap(bitmap.bitmap)
 * }
 * ```
 */
open class MuPDFDocument private constructor(
    /** Opaque pointer to the native `DocHandle`. */
    internal var nativeHandle: Long
) : AutoCloseable {

    private var closed = false

    // ─────────────────────────────────────────────────────────────────────────
    // Companion / factory
    // ─────────────────────────────────────────────────────────────────────────

    companion object {
        init {
            System.loadLibrary("mupdf_mobile")
        }

        /**
         * Opens a document at the given file-system path.
         *
         * @param path Absolute path to the PDF (or other supported format).
         * @throws MuPDFFileNotFoundException if the path does not exist.
         * @throws MuPDFInvalidDocumentException if the file cannot be parsed.
         */
        @JvmStatic
        @Throws(MuPDFFileNotFoundException::class, MuPDFInvalidDocumentException::class)
        fun open(path: String): MuPDFDocument {
            if (!File(path).exists()) throw MuPDFFileNotFoundException(path)
            val handle = nativeOpen(path)
            if (handle == -1L) throw MuPDFInvalidDocumentException()
            return MuPDFDocument(handle)
        }

        /**
         * Opens a document from in-memory bytes.
         *
         * @param data Raw bytes of a supported document format.
         * @throws MuPDFInvalidDocumentException if the data cannot be parsed.
         */
        @JvmStatic
        @Throws(MuPDFInvalidDocumentException::class)
        fun open(data: ByteArray): MuPDFDocument {
            if (data.isEmpty()) throw MuPDFInvalidDocumentException()
            val handle = nativeOpenFromBytes(data)
            if (handle == -1L) throw MuPDFInvalidDocumentException()
            return MuPDFDocument(handle)
        }

        // JNI bridge
        @JvmStatic private external fun nativeOpen(path: String): Long
        @JvmStatic private external fun nativeOpenFromBytes(data: ByteArray): Long
        @JvmStatic private external fun nativeGetPageCount(docHandle: Long): Int
        @JvmStatic private external fun nativeLoadPage(docHandle: Long, index: Int): Long
        @JvmStatic private external fun nativeGetPageWidth(docHandle: Long, index: Int): Float
        @JvmStatic private external fun nativeGetPageHeight(docHandle: Long, index: Int): Float
        @JvmStatic private external fun nativeSave(docHandle: Long, path: String): Boolean
        @JvmStatic private external fun nativeMerge(dstHandle: Long, srcHandle: Long)
        @JvmStatic private external fun nativeInsertBlankPage(docHandle: Long, index: Int, width: Float, height: Float)
        @JvmStatic private external fun nativeDeletePage(docHandle: Long, index: Int)
        @JvmStatic private external fun nativeGetMetadata(docHandle: Long, key: String): String?
        @JvmStatic private external fun nativeClose(docHandle: Long)
        @JvmStatic private external fun nativeGetOutline(docHandle: Long): Array<String>
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Properties
    // ─────────────────────────────────────────────────────────────────────────

    /** Total number of pages in the document. */
    val pageCount: Int
        get() {
            checkNotClosed()
            if (nativeHandle == -1L) return 0
            return nativeGetPageCount(nativeHandle)
        }

    /** The document's title metadata, or `null` if absent. */
    val title: String?
        get() {
            checkNotClosed()
            if (nativeHandle == -1L) return null
            return nativeGetMetadata(nativeHandle, "info:Title")
        }

    /** The document's author metadata, or `null` if absent. */
    val author: String?
        get() {
            checkNotClosed()
            if (nativeHandle == -1L) return null
            return nativeGetMetadata(nativeHandle, "info:Author")
        }

    // ─────────────────────────────────────────────────────────────────────────
    // Page access
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Loads the page at the given zero-based index.
     *
     * @param index Zero-based page index (0 until [pageCount]).
     * @throws MuPDFDocumentClosedException if the document is closed.
     * @throws MuPDFPageOutOfBoundsException if [index] is out of range.
     */
    @Throws(MuPDFDocumentClosedException::class, MuPDFPageOutOfBoundsException::class)
    open fun loadPage(index: Int): MuPDFPage {
        checkNotClosed()
        val count = pageCount
        if (index < 0 || index >= count) {
            throw MuPDFPageOutOfBoundsException(index, count)
        }
        val pageHandle = nativeLoadPage(nativeHandle, index)
        if (pageHandle == -1L) throw MuPDFEngineException("Failed to load page $index")
        val w = nativeGetPageWidth(nativeHandle, index)
        val h = nativeGetPageHeight(nativeHandle, index)
        return MuPDFPage(index, w, h, pageHandle)
    }

    /**
     * Returns the size (width × height in PDF points) of the page at [index]
     * without loading the full page object.
     */
    open fun pageSize(at: Int): SizeF {
        checkNotClosed()
        if (nativeHandle == -1L || at < 0 || at >= pageCount) return SizeF(0f, 0f)
        val w = nativeGetPageWidth(nativeHandle, at)
        val h = nativeGetPageHeight(nativeHandle, at)
        return SizeF(w, h)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Save
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Saves the document (with any modifications) to [path].
     *
     * @throws MuPDFDocumentClosedException if the document is closed.
     * @throws MuPDFSaveException if the write fails.
     */
    @Throws(MuPDFDocumentClosedException::class, MuPDFSaveException::class)
    open fun save(path: String) {
        checkNotClosed()
        if (nativeHandle == -1L) return
        val ok = nativeSave(nativeHandle, path)
        if (!ok) throw MuPDFSaveException(path)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Editing
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Appends all pages from [document] to the end of this document.
     *
     * @throws MuPDFDocumentClosedException if either document is closed.
     */
    @Throws(MuPDFDocumentClosedException::class)
    open fun merge(document: MuPDFDocument) {
        checkNotClosed()
        if (document.closed) throw MuPDFDocumentClosedException()
        if (nativeHandle == -1L || document.nativeHandle == -1L) return
        nativeMerge(nativeHandle, document.nativeHandle)
    }

    /**
     * Inserts a blank page at [index] with the given dimensions.
     *
     * @param index  Zero-based position for the new page.
     * @param width  Page width in PDF points.
     * @param height Page height in PDF points.
     * @throws MuPDFDocumentClosedException if the document is closed.
     */
    @Throws(MuPDFDocumentClosedException::class)
    open fun insertBlankPage(index: Int, width: Float, height: Float) {
        checkNotClosed()
        if (nativeHandle == -1L) return
        nativeInsertBlankPage(nativeHandle, index, width, height)
    }

    /**
     * Deletes pages at the specified zero-based indices.
     *
     * Indices are processed in descending order to avoid shifting.
     *
     * @throws MuPDFDocumentClosedException if the document is closed.
     * @throws MuPDFPageOutOfBoundsException if any index is out of range.
     */
    @Throws(MuPDFDocumentClosedException::class, MuPDFPageOutOfBoundsException::class)
    open fun deletePages(indices: List<Int>) {
        checkNotClosed()
        val count = pageCount
        indices.sortedDescending().forEach { index ->
            if (index < 0 || index >= count) throw MuPDFPageOutOfBoundsException(index, count)
            if (nativeHandle != -1L) nativeDeletePage(nativeHandle, index)
        }
    }

    /**
     * Returns the document's table of contents as a list of [MuPDFOutlineItem] roots.
     * Returns an empty list if the document has no outline or is closed.
     */
    open fun outline(): List<MuPDFOutlineItem> {
        checkNotClosed()
        if (nativeHandle == -1L) return emptyList()
        val flat = nativeGetOutline(nativeHandle)
        return parseOutlineItems(flat)
    }

    private fun parseOutlineItems(flat: Array<String>): List<MuPDFOutlineItem> {
        if (flat.isEmpty()) return emptyList()
        // Stack-based DFS reconstruction from the flat depth-annotated list.
        data class Entry(val depth: Int, val item: MuPDFOutlineItem, val children: MutableList<MuPDFOutlineItem>)
        val stack = mutableListOf<Entry>()
        val roots = mutableListOf<MuPDFOutlineItem>()

        for (line in flat) {
            val parts = line.split("\t", limit = 3)
            if (parts.size < 3) continue
            val depth = parts[0].toIntOrNull() ?: 0
            val title = parts[1]
            val pageIndex = parts[2].toIntOrNull() ?: -1
            val children = mutableListOf<MuPDFOutlineItem>()
            val item = MuPDFOutlineItem(title, pageIndex, children)
            val entry = Entry(depth, item, children)

            // Pop stack back to the parent level.
            while (stack.isNotEmpty() && stack.last().depth >= depth) {
                stack.removeLast()
            }
            if (stack.isEmpty()) {
                roots.add(item)
            } else {
                stack.last().children.add(item)
            }
            stack.add(entry)
        }
        return roots
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Releases all native resources. Safe to call multiple times.
     *
     * After calling `close()`, further operations will throw
     * [MuPDFDocumentClosedException].
     */
    override fun close() {
        if (closed) return
        closed = true
        if (nativeHandle != -1L) {
            nativeClose(nativeHandle)
            nativeHandle = -1L
        }
    }

    @Suppress("ProtectedInFinal")
    protected fun finalize() {
        close()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun checkNotClosed() {
        if (closed) throw MuPDFDocumentClosedException()
    }
}
