package com.artifex.mupdf.mobile

/**
 * Utility object for rendering [MuPDFPage] objects to [MuPDFBitmap] instances.
 *
 * All methods are static (JVM: use as a companion/object). Particularly
 * convenient for tiled rendering inside `RecyclerView`-based PDF viewers.
 *
 * ## Example
 * ```kotlin
 * val bitmap = MuPDFRenderer.render(page, scale = 2f)
 * imageView.setImageBitmap(bitmap.bitmap)
 * ```
 */
object MuPDFRenderer {

    /**
     * Recommended tile size in pixels for the current device characteristics.
     *
     * Smaller tiles use less memory at the cost of more frequent re-renders
     * during scroll and zoom.
     */
    const val RECOMMENDED_TILE_SIZE = 512

    // ─────────────────────────────────────────────────────────────────────────
    // Full-page rendering
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Renders an entire page at the given scale factor.
     *
     * @param page  The page to render.
     * @param scale Scale factor relative to PDF points (e.g. 2f for a 2×
     *   high-density render matching a 2× display).
     * @return A [MuPDFBitmap] with dimensions `(page.width × scale, page.height × scale)`.
     */
    @JvmStatic
    fun render(page: MuPDFPage, scale: Float): MuPDFBitmap = page.render(scale)

    /**
     * Renders an entire page at the specified pixel dimensions.
     *
     * @param page   The page to render.
     * @param width  Desired output width in pixels.
     * @param height Desired output height in pixels.
     * @return A [MuPDFBitmap] of the requested size.
     */
    @JvmStatic
    fun render(page: MuPDFPage, width: Int, height: Int): MuPDFBitmap =
        page.render(width, height)

    // ─────────────────────────────────────────────────────────────────────────
    // Tiled rendering
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Renders a sub-tile of a page.
     *
     * Tile coordinates are in the scaled pixel-space of the fully-rendered
     * page. Ideal for implementing tiled `RecyclerView` or `TileProvider`
     * based viewers.
     *
     * @param page       The page to render.
     * @param tileX      Left edge of the tile in scaled pixels.
     * @param tileY      Top edge of the tile in scaled pixels.
     * @param tileWidth  Tile width in pixels.
     * @param tileHeight Tile height in pixels.
     * @param scale      Scale factor for the virtual full-page coordinate space.
     * @return A [MuPDFBitmap] containing just the requested tile.
     */
    @JvmStatic
    fun renderTile(
        page: MuPDFPage,
        tileX: Int,
        tileY: Int,
        tileWidth: Int,
        tileHeight: Int,
        scale: Float
    ): MuPDFBitmap = page.renderTile(tileX, tileY, tileWidth, tileHeight, scale)
}
