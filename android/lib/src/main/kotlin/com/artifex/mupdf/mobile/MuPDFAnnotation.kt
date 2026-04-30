package com.artifex.mupdf.mobile

/**
 * Represents a single PDF annotation on a [MuPDFPage].
 *
 * Modifications to properties are staged in memory. Call [update] to flush
 * them to the underlying PDF structure. Changes are not written to disk until
 * [MuPDFDocument.save] is called.
 *
 * @property type     The type of this annotation.
 * @property rect     Bounding rectangle in PDF user-space points.
 * @property color    Stroke / fill colour of the annotation.
 * @property opacity  Opacity in [0, 1]. 1 = fully opaque.
 * @property contents Text content / comment associated with the annotation.
 */
open class MuPDFAnnotation internal constructor(
    val type: MuPDFAnnotationType,
    var rect: MuPDFRect,
    var color: MuPDFColor = MuPDFColor.HighlightYellow,
    var opacity: Float = 1f,
    var contents: String = "",
    /** Opaque handle to the native `AnnotHandle *`. -1 means not yet backed by native. */
    internal val nativeHandle: Long = -1L,
    internal val page: MuPDFPage? = null
) {
    init {
        require(opacity in 0f..1f) { "opacity must be in [0, 1]" }
    }

    /**
     * Flushes any pending property changes to the underlying PDF annotation.
     *
     * Must be called after modifying [rect], [color], [opacity], or
     * [contents] to ensure the changes are reflected when the document is
     * saved.
     */
    open fun update() {
        if (nativeHandle == -1L) return
        nativeUpdateAnnotation(
            nativeHandle,
            rect.x, rect.y, rect.x + rect.width, rect.y + rect.height,
            color.r, color.g, color.b, color.a,
            opacity,
            contents
        )
    }

    override fun toString(): String =
        "MuPDFAnnotation(type=${type.displayName}, rect=$rect, opacity=$opacity)"

    companion object {
        @JvmStatic
        private external fun nativeUpdateAnnotation(
            nativeHandle: Long,
            x0: Float, y0: Float, x1: Float, y1: Float,
            r: Float, g: Float, b: Float, a: Float,
            opacity: Float,
            contents: String
        )

        /** Returns the PDF_ANNOT_* enum value for the given handle. */
        @JvmStatic
        internal external fun nativeGetAnnotationType(annotHandle: Long): Int

        /** Returns [x0, y0, x1, y1] of the annotation's bounding rectangle. */
        @JvmStatic
        internal external fun nativeGetAnnotationRect(annotHandle: Long): FloatArray

        /** Returns [r, g, b, opacity] for the annotation colour. */
        @JvmStatic
        internal external fun nativeGetAnnotationColor(annotHandle: Long): FloatArray

        /** Returns the annotation's text contents, or empty string. */
        @JvmStatic
        internal external fun nativeGetAnnotationContents(annotHandle: Long): String?

        /** Releases the native AnnotHandle. */
        @JvmStatic
        internal external fun nativeDropAnnotation(annotHandle: Long)
    }
}
