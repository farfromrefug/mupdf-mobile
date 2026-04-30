import Foundation

// MARK: - MuPDFRenderer

/// Utility class for rendering ``MuPDFPage`` objects to ``MuPDFBitmap``
/// instances.
///
/// `MuPDFRenderer` is a stateless utility — all methods are static. It is
/// particularly convenient for tiled rendering inside `UICollectionView` or
/// `UIScrollView` based viewers.
///
/// ## Example
/// ```swift
/// let bitmap = MuPDFRenderer.render(page: page, scale: UIScreen.main.scale)
/// imageView.image = bitmap.image
/// ```
#if canImport(ObjectiveC)
@objcMembers
#endif
public final class MuPDFRenderer: NSObject {

    // Private — not meant to be instantiated.
    private override init() {}

    // -------------------------------------------------------------------------
    // MARK: Full-page rendering
    // -------------------------------------------------------------------------

    /// Renders an entire page at the given scale factor.
    ///
    /// - Parameters:
    ///   - page:  The page to render.
    ///   - scale: Scale factor relative to PDF points (use
    ///            `UIScreen.main.scale` for Retina bitmaps).
    /// - Returns: A ``MuPDFBitmap`` with dimensions
    ///            `(page.width × scale, page.height × scale)`.
    public static func render(page: MuPDFPage, scale: Float) -> MuPDFBitmap {
        page.render(scale: scale)
    }

    /// Renders an entire page at the specified pixel dimensions.
    ///
    /// - Parameters:
    ///   - page:   The page to render.
    ///   - width:  Desired output width in pixels.
    ///   - height: Desired output height in pixels.
    /// - Returns: A ``MuPDFBitmap`` of the requested size.
    public static func render(page: MuPDFPage, width: Int, height: Int) -> MuPDFBitmap {
        page.render(width: width, height: height)
    }

    // -------------------------------------------------------------------------
    // MARK: Tiled rendering
    // -------------------------------------------------------------------------

    /// Renders a rectangular sub-tile of a page.
    ///
    /// Use this method when implementing a tiled scroll view or
    /// `UICollectionView`-based viewer to render only the tiles that are
    /// currently visible. Tile coordinates are in the scaled (pixel) space of
    /// the fully-rendered page.
    ///
    /// - Parameters:
    ///   - page:       The page to render.
    ///   - tileX:      Left edge of the tile in scaled pixels.
    ///   - tileY:      Top edge of the tile in scaled pixels.
    ///   - tileWidth:  Width of the tile in pixels.
    ///   - tileHeight: Height of the tile in pixels.
    ///   - scale:      The overall scale factor of the virtual full-page
    ///                 coordinate space.
    /// - Returns: A ``MuPDFBitmap`` containing the tile pixels.
    public static func renderTile(
        page: MuPDFPage,
        tileX: Int,
        tileY: Int,
        tileWidth: Int,
        tileHeight: Int,
        scale: Float
    ) -> MuPDFBitmap {
        page.renderTile(
            x: tileX, y: tileY,
            tileWidth: tileWidth, tileHeight: tileHeight,
            scale: scale
        )
    }

    // -------------------------------------------------------------------------
    // MARK: Optimal tile size helper
    // -------------------------------------------------------------------------

    /// Returns a reasonable tile size for the current device.
    ///
    /// On memory-constrained devices smaller tiles reduce peak memory usage
    /// at the cost of more frequent re-renders during scrolling.
    public static var recommendedTileSize: Int {
#if os(iOS)
        // 512 × 512 px tiles strike a good balance on modern iOS devices.
        return 512
#else
        return 1024
#endif
    }
}
