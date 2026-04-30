package com.artifex.mupdf.mobile

import android.graphics.Bitmap

/**
 * A platform-native bitmap produced by rendering a [MuPDFPage].
 *
 * Wraps an [android.graphics.Bitmap] and exposes its dimensions.
 *
 * @property bitmap The underlying Android [Bitmap].
 */
open class MuPDFBitmap(val bitmap: Bitmap) {

    /** Width of the bitmap in pixels. */
    val width: Int get() = bitmap.width

    /** Height of the bitmap in pixels. */
    val height: Int get() = bitmap.height

    /**
     * Recycles the underlying [Bitmap] and frees native memory.
     *
     * After calling this method, any access to [bitmap] will throw.
     */
    fun recycle() {
        if (!bitmap.isRecycled) {
            bitmap.recycle()
        }
    }

    override fun toString() = "MuPDFBitmap(${width}×${height})"

    companion object {
        /**
         * Creates a blank (white) [MuPDFBitmap] with the given dimensions.
         *
         * @param width  Bitmap width in pixels.
         * @param height Bitmap height in pixels.
         */
        @JvmStatic
        fun blank(width: Int, height: Int): MuPDFBitmap {
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bmp.eraseColor(android.graphics.Color.WHITE)
            return MuPDFBitmap(bmp)
        }
    }
}
