package com.artifex.mupdf.mobile

import org.junit.Assert.*
import org.junit.Test

class MuPDFAnnotationTest {

    private fun makePage() = MuPDFPage(0, 595f, 842f, -1L)

    // ─────────────────────────────────────────────────────────────────────────
    // Type
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `type is preserved for all annotation types`() {
        val page = makePage()
        val rect = MuPDFRect(0f, 0f, 100f, 20f)
        MuPDFAnnotationType.values().forEach { type ->
            val annot = page.addAnnotation(type, rect)
            assertEquals("Type mismatch for $type", type, annot.type)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Rect
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `rect is preserved`() {
        val page = makePage()
        val rect = MuPDFRect(10f, 20f, 150f, 30f)
        val annot = page.addAnnotation(MuPDFAnnotationType.Square, rect)
        assertEquals(10f,  annot.rect.x,      0.001f)
        assertEquals(20f,  annot.rect.y,      0.001f)
        assertEquals(150f, annot.rect.width,  0.001f)
        assertEquals(30f,  annot.rect.height, 0.001f)
    }

    @Test
    fun `rect can be updated`() {
        val page = makePage()
        val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, MuPDFRect(0f, 0f, 100f, 20f))
        annot.rect = MuPDFRect(50f, 60f, 200f, 40f)
        assertEquals(50f, annot.rect.x, 0.001f)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Color
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `default color is HighlightYellow`() {
        val page = makePage()
        val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, MuPDFRect(0f, 0f, 100f, 20f))
        assertEquals(MuPDFColor.HighlightYellow.r, annot.color.r, 0.001f)
        assertEquals(MuPDFColor.HighlightYellow.g, annot.color.g, 0.001f)
    }

    @Test
    fun `color can be changed`() {
        val page = makePage()
        val annot = page.addAnnotation(MuPDFAnnotationType.Ink, MuPDFRect(0f, 0f, 100f, 20f))
        annot.color = MuPDFColor(0f, 0.5f, 1f, 0.8f)
        assertEquals(0f,   annot.color.r, 0.001f)
        assertEquals(0.5f, annot.color.g, 0.001f)
        assertEquals(1f,   annot.color.b, 0.001f)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Opacity
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `default opacity is 1`() {
        val page = makePage()
        val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, MuPDFRect(0f, 0f, 100f, 20f))
        assertEquals(1f, annot.opacity, 0.001f)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `opacity out of range throws`() {
        // Direct constructor validation
        MuPDFAnnotation(MuPDFAnnotationType.Highlight, MuPDFRect(0f, 0f, 1f, 1f), opacity = 1.5f)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Contents
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `contents round-trip`() {
        val page = makePage()
        val annot = page.addAnnotation(MuPDFAnnotationType.Text, MuPDFRect(0f, 0f, 100f, 20f))
        annot.contents = "Review this paragraph."
        assertEquals("Review this paragraph.", annot.contents)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // update (smoke test)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `update does not throw`() {
        val page = makePage()
        val annot = page.addAnnotation(MuPDFAnnotationType.Highlight, MuPDFRect(0f, 0f, 100f, 20f))
        annot.color    = MuPDFColor(1f, 0f, 0f, 0.5f)
        annot.contents = "Changed"
        annot.update() // must not throw
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MuPDFAnnotationType helpers
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `fromPdfAnnotValue round-trip`() {
        MuPDFAnnotationType.values().forEach { type ->
            val recovered = MuPDFAnnotationType.fromPdfAnnotValue(type.pdfAnnotValue)
            assertEquals(type, recovered)
        }
    }

    @Test
    fun `fromPdfAnnotValue returns null for unknown value`() {
        assertNull(MuPDFAnnotationType.fromPdfAnnotValue(999))
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MuPDFColor helpers
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    fun `toArgbInt opaque white`() {
        val white = MuPDFColor.White.toArgbInt()
        assertEquals(0xFFFFFFFF.toInt(), white)
    }

    @Test
    fun `toArgbInt opaque black`() {
        val black = MuPDFColor.Black.toArgbInt()
        assertEquals(0xFF000000.toInt(), black)
    }
}
