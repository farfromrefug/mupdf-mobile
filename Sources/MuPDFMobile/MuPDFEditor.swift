import Foundation

// MARK: - MuPDFEditor

/// Provides document-level editing operations such as image insertion and
/// redaction.
///
/// An `MuPDFEditor` is always associated with a specific ``MuPDFDocument``.
/// Changes made via the editor are held in memory until
/// ``MuPDFDocument/save(to:)`` is called.
///
/// ## Example
/// ```swift
/// let editor = MuPDFEditor(document: doc)
/// let page = try doc.loadPage(at: 0)
/// let imageData = try Data(contentsOf: stampURL)
/// let stampRect  = MuPDFRect(x: 400, y: 600, width: 150, height: 60)
/// try editor.insertImage(on: page, image: imageData, rect: stampRect)
///
/// let redactRect = MuPDFRect(x: 50, y: 100, width: 200, height: 20)
/// try editor.redact(page: page, rect: redactRect)
/// try editor.applyRedactions()
///
/// try doc.save(to: outputPath)
/// ```
@objc public final class MuPDFEditor: NSObject {

    // -------------------------------------------------------------------------
    // MARK: Properties
    // -------------------------------------------------------------------------

    /// The document this editor is operating on.
    @objc public private(set) weak var document: MuPDFDocument?

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    /// Creates an editor bound to the given document.
    ///
    /// - Parameter document: The document to edit. Must not be closed.
    @objc public init(document: MuPDFDocument) {
        self.document = document
    }

    // -------------------------------------------------------------------------
    // MARK: Image insertion
    // -------------------------------------------------------------------------

    /// Inserts an image onto a page at the specified rectangle.
    ///
    /// Supported image formats: JPEG, PNG, and any format decodable by MuPDF.
    ///
    /// - Parameters:
    ///   - page:  The target page.
    ///   - image: Raw image bytes (JPEG / PNG / …).
    ///   - rect:  Bounding rectangle in PDF user-space points where the image
    ///            should be placed.
    /// - Throws: `MuPDFError.documentClosed` or `MuPDFError.mupdfError`.
    @objc public func insertImage(
        on page: MuPDFPage,
        image: Data,
        rect: MuPDFRect
    ) throws {
        guard let document, !image.isEmpty else {
            throw MuPDFError.documentClosed
        }
        _ = document  // suppress unused warning until TODO is filled

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let pdfDoc = pdf_document_from_fz_document(ctx, document.nativeDoc)
        //   let pdfPage = pdf_page_from_fz_page(ctx, page.nativePage)
        //
        //   // Decode the image
        //   image.withUnsafeBytes { ptr in
        //       let buf = fz_new_buffer_from_copied_data(ctx, ptr.baseAddress, image.count)
        //       let fzImage = fz_new_image_from_buffer(ctx, buf)
        //       let (x0, y0, x1, y1) = toFzRect(rect)
        //       let matrix = fz_make_matrix(x1 - x0, 0, 0, y1 - y0, x0, y0)
        //       pdf_add_image_to_page(ctx, pdfDoc, pdfPage, fzImage, matrix)
        //       fz_drop_image(ctx, fzImage)
        //   }
    }

    // -------------------------------------------------------------------------
    // MARK: Redaction
    // -------------------------------------------------------------------------

    /// Marks a rectangular region on a page for redaction.
    ///
    /// The region is visually covered but the underlying content is not
    /// removed until ``applyRedactions()`` is called.
    ///
    /// - Parameters:
    ///   - page: The page containing the content to redact.
    ///   - rect: Rectangle to redact in PDF user-space points.
    /// - Throws: `MuPDFError.documentClosed` or `MuPDFError.mupdfError`.
    @objc public func redact(page: MuPDFPage, rect: MuPDFRect) throws {
        guard document != nil else { throw MuPDFError.documentClosed }

        // TODO: (requires mupdf submodule)
        //   let annot = pdf_create_annot(ctx, pdfPage, PDF_ANNOT_REDACT)
        //   let (x0, y0, x1, y1) = toFzRect(rect)
        //   pdf_set_annot_rect(ctx, annot, fz_make_rect(x0, y0, x1, y1))
        //   pdf_update_annot(ctx, annot)
        _ = try page.addAnnotation(type: .redact, rect: rect)
    }

    /// Permanently removes all content covered by redaction annotations on
    /// all pages of the document.
    ///
    /// ⚠️ This operation is **irreversible**. Save a backup before calling.
    ///
    /// - Throws: `MuPDFError.documentClosed` or `MuPDFError.mupdfError`.
    @objc public func applyRedactions() throws {
        guard document != nil else { throw MuPDFError.documentClosed }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let pdfDoc = pdf_document_from_fz_document(ctx, document.nativeDoc)
        //   pdf_redact_page(ctx, pdfDoc, pdfPage, nil)
    }
}
