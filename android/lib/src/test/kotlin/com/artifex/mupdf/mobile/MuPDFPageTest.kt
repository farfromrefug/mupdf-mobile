package com.artifex.mupdf.mobile

import org.junit.Assert.*
import org.junit.Test

class MuPDFPageTest {

    private fun makePage(
        index: Int = 0,
        width: Float = 595f,
        height: Float = 842f
    ): MuPDFPage = MuPDFPage(index, width, height, -1L)

    // ─────────────────────────────────────────────────────────────────────────
    // Dimensions
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `page dimensions are preserved`() {
        val page = makePage(width = 612f, height = 792f) // US Letter
        assertEquals(612f, page.width, 0.001f)
        assertEquals(792f, page.height, 0.001f)
    }

    @Test
    fun `page index is preserved`() {
        val page = makePage(index = 5)
        assertEquals(5, page.index)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // render(scale)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `render scale 1 produces correct dimensions`() {
        val page = makePage(width = 595f, height = 842f)
        val bitmap = page.render(1f)
        assertEquals(595, bitmap.width)
        assertEquals(842, bitmap.height)
    }

    @Test
    fun `render scale 2 produces double dimensions`() {
        val page = makePage(width = 595f, height = 842f)
        val bitmap = page.render(2f)
        assertEquals(1190, bitmap.width)
        assertEquals(1684, bitmap.height)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // render(width, height)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `render with explicit dimensions`() {
        val page = makePage()
        val bitmap = page.render(300, 400)
        assertEquals(300, bitmap.width)
        assertEquals(400, bitmap.height)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `render zero width throws`() {
        makePage().render(0, 100)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // renderTile
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `renderTile returns tile-sized bitmap`() {
        val page = makePage()
        val tile = page.renderTile(0, 0, 256, 256, 1f)
        assertEquals(256, tile.width)
        assertEquals(256, tile.height)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `renderTile zero dimensions throws`() {
        makePage().renderTile(0, 0, 0, 0, 1f)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // annotations
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `annotations returns empty list initially`() {
        val page = makePage()
        assertTrue(page.annotations().isEmpty())
    }

    @Test
    fun `addAnnotation returns annotation with matching type`() {
        val page = makePage()
        val rect = MuPDFRect(10f, 20f, 100f, 30f)
        val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, rect)
        assertEquals(MuPDFAnnotationType.Highlight, annot.type)
        assertEquals(10f, annot.rect.x, 0.001f)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // search
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `search empty string returns empty list`() {
        val page = makePage()
        assertTrue(page.search("").isEmpty())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // textContent
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `textContent returns string`() {
        val page = makePage()
        assertNotNull(page.textContent)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // close
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `close is idempotent`() {
        val page = makePage()
        page.close()
        page.close() // must not throw
    }

    @Test(expected = MuPDFDocumentClosedException::class)
    fun `render after close throws`() {
        val page = makePage()
        page.close()
        page.render(1f)
    }
}
