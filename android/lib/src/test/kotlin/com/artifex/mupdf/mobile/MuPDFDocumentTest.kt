package com.artifex.mupdf.mobile

import org.junit.Assert.*
import org.junit.Test

class MuPDFDocumentTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Factory — open from bytes
    // ─────────────────────────────────────────────────────────────────────────

    @Test(expected = MuPDFInvalidDocumentException::class)
    fun `open empty bytes throws MuPDFInvalidDocumentException`() {
        MuPDFDocument.open(byteArrayOf())
    }

    @Test
    fun `open minimal PDF header does not throw`() {
        // %PDF header bytes
        val pdfHeader = byteArrayOf(0x25, 0x50, 0x44, 0x46)
        val doc = MuPDFDocument.open(pdfHeader)
        assertNotNull(doc)
        doc.close()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // pageCount
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `pageCount returns non-negative value`() {
        val doc = MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46))
        assertTrue("pageCount should be >= 0", doc.pageCount >= 0)
        doc.close()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // loadPage
    // ─────────────────────────────────────────────────────────────────────────

    @Test(expected = MuPDFPageOutOfBoundsException::class)
    fun `loadPage out of bounds throws`() {
        val doc = MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46))
        try {
            doc.loadPage(999)
        } finally {
            doc.close()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // close
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `close is idempotent`() {
        val doc = MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46))
        doc.close()
        doc.close() // must not throw
    }

    @Test(expected = MuPDFDocumentClosedException::class)
    fun `operation after close throws MuPDFDocumentClosedException`() {
        val doc = MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46))
        doc.close()
        doc.loadPage(0) // should throw
    }

    // ─────────────────────────────────────────────────────────────────────────
    // metadata
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `title and author are null before submodule`() {
        val doc = MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46))
        // Pre-submodule: metadata is not available
        assertNull(doc.title)
        assertNull(doc.author)
        doc.close()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // deletePages
    // ─────────────────────────────────────────────────────────────────────────

    @Test(expected = MuPDFPageOutOfBoundsException::class)
    fun `deletePages with out-of-bounds index throws`() {
        val doc = MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46))
        try {
            doc.deletePages(listOf(0, 999))
        } finally {
            doc.close()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // use block (AutoCloseable)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `use block closes document automatically`() {
        var pageCount = -1
        MuPDFDocument.open(byteArrayOf(0x25, 0x50, 0x44, 0x46)).use { doc ->
            pageCount = doc.pageCount
        }
        assertTrue(pageCount >= 0)
    }
}
