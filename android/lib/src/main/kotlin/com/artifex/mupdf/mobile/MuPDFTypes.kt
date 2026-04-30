package com.artifex.mupdf.mobile

// ─────────────────────────────────────────────────────────────────────────────
// MuPDFRect
// ─────────────────────────────────────────────────────────────────────────────

/**
 * A rectangle in PDF user-space coordinates.
 *
 * @property x      X coordinate of the top-left corner, in points.
 * @property y      Y coordinate of the top-left corner, in points.
 * @property width  Width of the rectangle, in points.
 * @property height Height of the rectangle, in points.
 */
data class MuPDFRect(
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float
) {
    /** Returns a new [MuPDFRect] inset (or outset for negative values) by [dx] and [dy]. */
    fun inset(dx: Float, dy: Float) = MuPDFRect(x + dx, y + dy, width - 2 * dx, height - 2 * dy)

    /** Returns `true` if this rectangle contains the point ([px], [py]). */
    fun contains(px: Float, py: Float): Boolean =
        px >= x && px <= x + width && py >= y && py <= y + height

    override fun toString() = "MuPDFRect(x=$x, y=$y, width=$width, height=$height)"
}

// ─────────────────────────────────────────────────────────────────────────────
// MuPDFColor
// ─────────────────────────────────────────────────────────────────────────────

/**
 * An RGBA colour. All components are in the range [0f, 1f].
 *
 * @property r Red component.
 * @property g Green component.
 * @property b Blue component.
 * @property a Alpha component (1 = fully opaque).
 */
data class MuPDFColor(
    val r: Float,
    val g: Float,
    val b: Float,
    val a: Float = 1f
) {
    companion object {
        /** Opaque black. */
        val Black = MuPDFColor(0f, 0f, 0f)
        /** Opaque white. */
        val White = MuPDFColor(1f, 1f, 1f)
        /** Semi-transparent yellow — useful as a highlight colour. */
        val HighlightYellow = MuPDFColor(1f, 1f, 0f, 0.5f)
        /** Semi-transparent red. */
        val HighlightRed = MuPDFColor(1f, 0f, 0f, 0.5f)
    }

    /** Returns the colour packed into an ARGB int (as used by [android.graphics.Color]). */
    fun toArgbInt(): Int {
        val a8 = (a * 255).toInt().coerceIn(0, 255)
        val r8 = (r * 255).toInt().coerceIn(0, 255)
        val g8 = (g * 255).toInt().coerceIn(0, 255)
        val b8 = (b * 255).toInt().coerceIn(0, 255)
        return (a8 shl 24) or (r8 shl 16) or (g8 shl 8) or b8
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MuPDFAnnotationType
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Enumeration of supported PDF annotation types.
 *
 * The [pdfAnnotValue] matches the `PDF_ANNOT_*` integer constants from the
 * MuPDF C API header `pdf-annot.h`.
 */
enum class MuPDFAnnotationType(val pdfAnnotValue: Int, val displayName: String) {
    /** Sticky-note (text comment). */
    Text(0, "Text"),
    /** Hyperlink annotation. */
    Link(1, "Link"),
    /** Free-text annotation drawn directly on the page. */
    FreeText(2, "FreeText"),
    /** Straight line. */
    Line(3, "Line"),
    /** Rectangle / box shape. */
    Square(4, "Square"),
    /** Ellipse / circle shape. */
    Circle(5, "Circle"),
    /** Free-hand ink drawing. */
    Ink(14, "Ink"),
    /** Yellow highlight over text. */
    Highlight(15, "Highlight"),
    /** Underline beneath text. */
    Underline(16, "Underline"),
    /** Squiggly underline. */
    Squiggly(17, "Squiggly"),
    /** Strikethrough over text. */
    StrikeOut(18, "StrikeOut"),
    /** Stamp annotation (e.g. "APPROVED"). */
    Stamp(20, "Stamp"),
    /** Redaction mark. Content is removed after [MuPDFEditor.applyRedactions]. */
    Redact(24, "Redact");

    companion object {
        /** Returns the [MuPDFAnnotationType] for the given [pdfAnnotValue], or `null`. */
        fun fromPdfAnnotValue(value: Int): MuPDFAnnotationType? =
            values().firstOrNull { it.pdfAnnotValue == value }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MuPDFException
// ─────────────────────────────────────────────────────────────────────────────

/** Base class for exceptions thrown by MuPDF Mobile. */
open class MuPDFException(message: String, cause: Throwable? = null) :
    Exception(message, cause)

/** Thrown when a file path cannot be found or opened. */
class MuPDFFileNotFoundException(path: String) :
    MuPDFException("File not found: $path")

/** Thrown when the provided data is not a valid document. */
class MuPDFInvalidDocumentException(message: String = "Invalid document") :
    MuPDFException(message)

/** Thrown when the requested page index is out of bounds. */
class MuPDFPageOutOfBoundsException(index: Int, pageCount: Int) :
    MuPDFException("Page index $index is out of bounds (pageCount=$pageCount)")

/** Thrown when an annotation cannot be created. */
class MuPDFAnnotationException(message: String) : MuPDFException(message)

/** Thrown when a save/write operation fails. */
class MuPDFSaveException(path: String, cause: Throwable? = null) :
    MuPDFException("Failed to save to: $path", cause)

/** Thrown when an operation is attempted on a closed document. */
class MuPDFDocumentClosedException :
    MuPDFException("The document has been closed")

/**
 * A single entry in a PDF's table of contents (outline / bookmark).
 *
 * @property title     Display title of this entry.
 * @property pageIndex Zero-based page index, or -1 if not a page link.
 * @property children  Nested child entries.
 */
data class MuPDFOutlineItem(
    val title: String,
    val pageIndex: Int,
    val children: List<MuPDFOutlineItem> = emptyList()
)
