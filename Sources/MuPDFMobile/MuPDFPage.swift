import Foundation

// MARK: - MuPDFPage

/// Represents a single page within a ``MuPDFDocument``.
///
/// Pages are loaded on demand via ``MuPDFDocument/loadPage(at:)`` and hold a
/// reference to the native `fz_page`. Release native resources by calling
/// ``invalidate()`` or by letting the page object be deallocated.
#if canImport(ObjectiveC)
@objcMembers
#endif
public final class MuPDFPage: NSObject {

    // -------------------------------------------------------------------------
    // MARK: Properties
    // -------------------------------------------------------------------------

    /// Zero-based index of this page within its parent document.
    public let index: Int

    /// Width of the page in PDF points (1 pt = 1/72 inch).
    public private(set) var width: Float = 0

    /// Height of the page in PDF points (1 pt = 1/72 inch).
    public private(set) var height: Float = 0

    /// Text content of the entire page, extracted as a plain-text string.
    public var textContent: String {
        guard !isInvalidated else { return "" }
        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let block = fz_new_stext_page(ctx, bounds)
        //   let device = fz_new_stext_device(ctx, block, nil)
        //   fz_run_page(ctx, nativePage, device, fz_identity, nil)
        //   fz_close_device(ctx, device)
        //   let buf = fz_new_buffer_from_stext_page(ctx, block)
        //   return String(cString: fz_string_from_buffer(ctx, buf))
        return ""
    }

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    private var nativePage: OpaquePointer?
    private weak var document: MuPDFDocument?
    private var isInvalidated = false

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    init(index: Int, document: MuPDFDocument, nativePage: OpaquePointer? = nil) {
        self.index = index
        self.document = document
        self.nativePage = nativePage
        super.init()
        loadDimensions()
    }

    deinit {
        invalidate()
    }

    // -------------------------------------------------------------------------
    // MARK: Rendering
    // -------------------------------------------------------------------------

    /// Renders the page at the given scale factor.
    ///
    /// - Parameter scale: Scale factor relative to PDF points (e.g. 2.0 for
    ///   a Retina / 2× render).
    /// - Returns: A ``MuPDFBitmap`` containing the rendered pixels.
    public func render(scale: Float) -> MuPDFBitmap {
        let pixelWidth  = Int(width  * scale)
        let pixelHeight = Int(height * scale)
        return render(width: pixelWidth, height: pixelHeight)
    }

    /// Renders the page at the specified pixel dimensions.
    ///
    /// - Parameters:
    ///   - width:  Output bitmap width in pixels.
    ///   - height: Output bitmap height in pixels.
    /// - Returns: A ``MuPDFBitmap`` containing the rendered pixels.
    public func render(width: Int, height: Int) -> MuPDFBitmap {
        guard !isInvalidated, width > 0, height > 0 else {
            return MuPDFBitmap(width: 0, height: 0)
        }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let scaleX = Float(width)  / self.width
        //   let scaleY = Float(height) / self.height
        //   let matrix = fz_scale(scaleX, scaleY)
        //   let bbox = fz_round_rect(fz_transform_rect(bounds, matrix))
        //   let pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), bbox, nil, 1)
        //   fz_clear_pixmap_with_value(ctx, pix, 0xFF)
        //   let device = fz_new_draw_device(ctx, matrix, pix)
        //   fz_run_page(ctx, nativePage, device, fz_identity, nil)
        //   fz_close_device(ctx, device)
        //   return MuPDFBitmap(pixmap: pix)

        return MuPDFBitmap(width: width, height: height)
    }

    /// Renders a sub-tile of the page.
    ///
    /// Useful for large-page tiled rendering in scroll / zoom views. The
    /// `tileX`/`tileY` origin is in the scaled (pixel) coordinate space of
    /// the full rendered page.
    ///
    /// - Parameters:
    ///   - x:         Left edge of the tile in scaled pixels.
    ///   - y:         Top edge of the tile in scaled pixels.
    ///   - tileWidth:  Width of the tile in pixels.
    ///   - tileHeight: Height of the tile in pixels.
    ///   - scale:     Scale factor used when computing the pixel coordinate space.
    /// - Returns: A ``MuPDFBitmap`` containing just the tile.
    public func renderTile(
        x: Int, y: Int,
        tileWidth: Int, tileHeight: Int,
        scale: Float
    ) -> MuPDFBitmap {
        guard !isInvalidated, tileWidth > 0, tileHeight > 0 else {
            return MuPDFBitmap(width: 0, height: 0)
        }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let matrix = fz_scale(scale, scale)
        //   let clip = fz_make_irect(Int32(x), Int32(y),
        //                            Int32(x + tileWidth), Int32(y + tileHeight))
        //   let pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), clip, nil, 1)
        //   fz_clear_pixmap_with_value(ctx, pix, 0xFF)
        //   let device = fz_new_draw_device(ctx, matrix, pix)
        //   fz_run_page(ctx, nativePage, device, fz_identity, nil)
        //   fz_close_device(ctx, device)
        //   return MuPDFBitmap(pixmap: pix)

        return MuPDFBitmap(width: tileWidth, height: tileHeight)
    }

    // -------------------------------------------------------------------------
    // MARK: Annotations
    // -------------------------------------------------------------------------

    /// Returns all annotations on this page.
    public func annotations() -> [MuPDFAnnotation] {
        guard !isInvalidated else { return [] }
        // TODO: (requires mupdf submodule)
        //   var annots: [MuPDFAnnotation] = []
        //   var annot = pdf_first_annot(ctx, pdfPage)
        //   while let a = annot {
        //       annots.append(MuPDFAnnotation(native: a, page: self))
        //       annot = pdf_next_annot(ctx, a)
        //   }
        //   return annots
        return []
    }

    /// Adds a new annotation of the specified type covering the given
    /// rectangle, and returns the created annotation.
    ///
    /// - Parameters:
    ///   - type: The annotation type (highlight, ink, stamp, …).
    ///   - rect: The bounding rectangle in PDF user-space points.
    /// - Returns: The newly created ``MuPDFAnnotation``.
    /// - Throws: `MuPDFError.annotationCreationFailed`.
    public func addAnnotation(
        type: MuPDFAnnotationType,
        rect: MuPDFRect
    ) throws -> MuPDFAnnotation {
        guard !isInvalidated else { throw MuPDFError.documentClosed }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let annot = pdf_create_annot(ctx, pdfPage, annotationTypeToMuPDF(type))
        //   let (x0, y0, x1, y1) = toFzRect(rect)
        //   pdf_set_annot_rect(ctx, annot, fz_make_rect(x0, y0, x1, y1))
        //   pdf_update_annot(ctx, annot)
        //   return MuPDFAnnotation(native: annot, page: self)

        let annotation = MuPDFAnnotation(type: type, rect: rect, page: self)
        return annotation
    }

    /// Removes the given annotation from this page.
    ///
    /// - Parameter annotation: The annotation to remove.
    /// - Throws: `MuPDFError.mupdfError` if removal fails.
    public func removeAnnotation(_ annotation: MuPDFAnnotation) throws {
        guard !isInvalidated else { throw MuPDFError.documentClosed }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   pdf_delete_annot(ctx, pdfPage, annotation.nativeAnnot)
    }

    // -------------------------------------------------------------------------
    // MARK: Text search
    // -------------------------------------------------------------------------

    /// Searches for all occurrences of `text` on this page.
    ///
    /// - Parameter text: The string to search for (case-insensitive).
    /// - Returns: An array of ``MuPDFRect`` values, one per match quad.
    public func search(text: String) -> [MuPDFRect] {
        guard !isInvalidated, !text.isEmpty else { return [] }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   var quads = [fz_quad](repeating: fz_quad(), count: 256)
        //   let count = fz_search_page(ctx, nativePage, text, nil, &quads, Int32(quads.count))
        //   return (0..<Int(count)).map { i in
        //       let r = fz_rect_from_quad(quads[i])
        //       return fromFzRect(x0: r.x0, y0: r.y0, x1: r.x1, y1: r.y1)
        //   }

        return []
    }

    // -------------------------------------------------------------------------
    // MARK: Lifecycle
    // -------------------------------------------------------------------------

    /// Releases the underlying native page object.
    public func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        // TODO: fz_drop_page(MuPDFContext.shared.ctx, nativePage)
        nativePage = nil
    }

    // -------------------------------------------------------------------------
    // MARK: Private helpers
    // -------------------------------------------------------------------------

    private func loadDimensions() {
        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let bounds = fz_bound_page(ctx, nativePage)
        //   width  = bounds.x1 - bounds.x0
        //   height = bounds.y1 - bounds.y0
        width  = 595  // A4 default placeholder
        height = 842
    }
}
