import Foundation

// MARK: - MuPDFAnnotation

/// Represents a single PDF annotation on a ``MuPDFPage``.
///
/// After modifying any property call ``update()`` to flush the change to the
/// underlying PDF structure.
#if canImport(ObjectiveC)
@objcMembers
#endif
public final class MuPDFAnnotation: NSObject {

    // -------------------------------------------------------------------------
    // MARK: Properties
    // -------------------------------------------------------------------------

    /// The type of this annotation.
    public private(set) var type: MuPDFAnnotationType

    /// Bounding rectangle of the annotation in PDF user-space points.
    public var rect: MuPDFRect {
        didSet { isDirty = true }
    }

    /// The annotation's stroke / fill colour.
    public var color: MuPDFColor {
        didSet { isDirty = true }
    }

    /// Opacity of the annotation in [0, 1]. 1 = fully opaque.
    public var opacity: Float {
        didSet {
            opacity = min(1, max(0, opacity))
            isDirty = true
        }
    }

    /// Text content / comment associated with the annotation.
    public var contents: String {
        didSet { isDirty = true }
    }

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    private var nativeAnnot: OpaquePointer?
    private weak var page: MuPDFPage?
    private var isDirty = false

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    init(
        type: MuPDFAnnotationType,
        rect: MuPDFRect,
        page: MuPDFPage,
        nativeAnnot: OpaquePointer? = nil
    ) {
        self.type       = type
        self.rect       = rect
        self.color      = .highlightYellow
        self.opacity    = 1.0
        self.contents   = ""
        self.page       = page
        self.nativeAnnot = nativeAnnot
    }

    deinit {
        // TODO: fz_drop_annot(MuPDFContext.shared.ctx, nativeAnnot)
    }

    // -------------------------------------------------------------------------
    // MARK: Update
    // -------------------------------------------------------------------------

    /// Flushes any pending property changes to the underlying PDF annotation.
    ///
    /// Call this after modifying ``rect``, ``color``, ``opacity``, or
    /// ``contents``. Changes are not persisted to disk until
    /// ``MuPDFDocument/save(to:)`` is called.
    public func update() {
        guard isDirty else { return }
        isDirty = false

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   // Update rect
        //   let (x0, y0, x1, y1) = toFzRect(rect)
        //   pdf_set_annot_rect(ctx, nativeAnnot, fz_make_rect(x0, y0, x1, y1))
        //   // Update colour
        //   var colorComponents = toFzColor(color)
        //   pdf_set_annot_color(ctx, nativeAnnot, Int32(colorComponents.count), &colorComponents)
        //   // Update opacity
        //   pdf_set_annot_opacity(ctx, nativeAnnot, opacity)
        //   // Update contents
        //   pdf_set_annot_contents(ctx, nativeAnnot, contents)
        //   pdf_update_annot(ctx, nativeAnnot)
    }

    // -------------------------------------------------------------------------
    // MARK: Description
    // -------------------------------------------------------------------------

    public override var description: String {
        "MuPDFAnnotation(type: \(type.name), rect: \(rect), opacity: \(opacity))"
    }
}
