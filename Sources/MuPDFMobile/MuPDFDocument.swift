import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

// MARK: - MuPDFDocument

/// A PDF (or XPS / CBZ / EPUB) document managed by the MuPDF engine.
///
/// ## Thread safety
/// Instances of `MuPDFDocument` are **not** thread-safe. All calls to a given
/// document must be made from the same thread (or serialised externally).
/// Use separate documents per background thread if concurrent rendering is
/// required.
///
/// ## Memory management
/// Call ``close()`` to release native resources as soon as the document is no
/// longer needed. The ARC destructor also calls `close()` as a safety net.
#if canImport(ObjectiveC)
@objcMembers
#endif
public final class MuPDFDocument: NSObject {

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    /// Opaque pointer to the underlying `fz_document`.
    private var nativeDoc: OpaquePointer?

    /// Whether the document has been explicitly closed.
    private var isClosed = false

    // -------------------------------------------------------------------------
    // MARK: Initialisation (private — use factory methods)
    // -------------------------------------------------------------------------

    private override init() {}

    private init(nativeDoc: OpaquePointer?) {
        self.nativeDoc = nativeDoc
    }

    deinit {
        close()
    }

    // -------------------------------------------------------------------------
    // MARK: Factory – open from path
    // -------------------------------------------------------------------------

    /// Opens a document at the given file-system path.
    ///
    /// - Parameter path: Absolute path to the PDF (or other supported format).
    /// - Returns: An initialised `MuPDFDocument`.
    /// - Throws: `MuPDFError.fileNotFound` if the path does not exist.
    ///           `MuPDFError.invalidDocument` if the file cannot be parsed.
    public static func open(path: String) throws -> MuPDFDocument {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MuPDFError.fileNotFound
        }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   guard let doc = fz_open_document(ctx, path) else {
        //       throw MuPDFError.invalidDocument
        //   }
        //   return MuPDFDocument(nativeDoc: doc)

        // Placeholder until submodule is available:
        let doc = MuPDFDocument()
        doc.nativeDoc = nil
        return doc
    }

    /// Opens a document from in-memory data.
    ///
    /// - Parameter data: The raw bytes of a PDF (or other supported format).
    /// - Returns: An initialised `MuPDFDocument`.
    /// - Throws: `MuPDFError.invalidDocument` if the data cannot be parsed.
    public static func open(data: Data) throws -> MuPDFDocument {
        guard !data.isEmpty else { throw MuPDFError.invalidDocument }

        // TODO: (requires mupdf submodule)
        //   data.withUnsafeBytes { ptr in
        //       let buf = fz_new_buffer_from_copied_data(ctx, ptr.baseAddress, data.count)
        //       let stream = fz_open_buffer(ctx, buf)
        //       let doc = fz_open_document_with_stream(ctx, "application/pdf", stream)
        //       ...
        //   }

        let doc = MuPDFDocument()
        doc.nativeDoc = nil
        return doc
    }

    // -------------------------------------------------------------------------
    // MARK: Document properties
    // -------------------------------------------------------------------------

    /// The total number of pages in the document.
    public var pageCount: Int {
        guard !isClosed else { return 0 }
        // TODO: return Int(fz_count_pages(MuPDFContext.shared.ctx, nativeDoc))
        return 0
    }

    /// The document's title metadata, if present.
    public var title: String? {
        guard !isClosed else { return nil }
        // TODO: return metadata(key: "info:Title")
        return nil
    }

    /// The document's author metadata, if present.
    public var author: String? {
        guard !isClosed else { return nil }
        // TODO: return metadata(key: "info:Author")
        return nil
    }

    // -------------------------------------------------------------------------
    // MARK: Page access
    // -------------------------------------------------------------------------

    /// Loads the page at the given zero-based index.
    ///
    /// - Parameter index: Zero-based page index (0 …< ``pageCount``).
    /// - Returns: The loaded ``MuPDFPage``.
    /// - Throws: `MuPDFError.documentClosed` or
    ///           `MuPDFError.pageIndexOutOfBounds`.
    public func loadPage(at index: Int) throws -> MuPDFPage {
        guard !isClosed else { throw MuPDFError.documentClosed }
        guard index >= 0 && index < pageCount else {
            throw MuPDFError.pageIndexOutOfBounds
        }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   guard let nativePage = fz_load_page(ctx, nativeDoc, Int32(index)) else {
        //       throw MuPDFError.mupdfError
        //   }
        //   return MuPDFPage(nativePage: nativePage, index: index, document: self)

        return MuPDFPage(index: index, document: self)
    }

    /// Returns the size (in PDF points) of the page at the given index
    /// without loading the full page object.
    ///
    /// - Parameter index: Zero-based page index.
    /// - Returns: The page size as a `CGSize`.
#if canImport(CoreGraphics)
    public func pageSize(at index: Int) -> CGSize {
        guard !isClosed, index >= 0, index < pageCount else { return .zero }
        // TODO: use fz_bound_page after loading
        return .zero
    }
#endif

    // -------------------------------------------------------------------------
    // MARK: Save
    // -------------------------------------------------------------------------

    /// Saves the document (with any modifications) to the specified path.
    ///
    /// - Parameter path: The destination file path.
    /// - Throws: `MuPDFError.documentClosed` or `MuPDFError.saveFailed`.
    public func save(to path: String) throws {
        guard !isClosed else { throw MuPDFError.documentClosed }
        guard !path.isEmpty else { throw MuPDFError.saveFailed }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let pdfDoc = pdf_document_from_fz_document(ctx, nativeDoc)
        //   pdf_save_document(ctx, pdfDoc, path, nil)
    }

    // -------------------------------------------------------------------------
    // MARK: Document editing
    // -------------------------------------------------------------------------

    /// Appends all pages from `document` to the end of this document.
    ///
    /// - Parameter document: The source document to merge from.
    /// - Throws: `MuPDFError.documentClosed` or `MuPDFError.mupdfError`.
    public func merge(document: MuPDFDocument) throws {
        guard !isClosed else { throw MuPDFError.documentClosed }
        guard !document.isClosed else { throw MuPDFError.documentClosed }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let dst = pdf_document_from_fz_document(ctx, nativeDoc)
        //   let src = pdf_document_from_fz_document(ctx, document.nativeDoc)
        //   pdf_merge_document(ctx, dst, src)
    }

    /// Inserts a blank page with the given dimensions at the specified index.
    ///
    /// - Parameters:
    ///   - index: Zero-based position at which to insert the new page.
    ///   - width:  Page width in PDF points (1 point = 1/72 inch).
    ///   - height: Page height in PDF points.
    /// - Throws: `MuPDFError.documentClosed` or `MuPDFError.mupdfError`.
    public func insertBlankPage(at index: Int, width: Float, height: Float) throws {
        guard !isClosed else { throw MuPDFError.documentClosed }

        // TODO: (requires mupdf submodule)
        //   let ctx = MuPDFContext.shared.ctx
        //   let pdfDoc = pdf_document_from_fz_document(ctx, nativeDoc)
        //   let mediabox = fz_make_rect(0, 0, width, height)
        //   pdf_insert_page(ctx, pdfDoc, Int32(index), pdf_add_page(ctx, pdfDoc, mediabox, 0, nil, nil))
    }

    /// Deletes pages at the specified zero-based indices.
    ///
    /// Indices are sorted and processed in reverse order so earlier deletions
    /// do not shift subsequent indices.
    ///
    /// - Parameter indices: The set of page indices to delete.
    /// - Throws: `MuPDFError.documentClosed`, `MuPDFError.pageIndexOutOfBounds`,
    ///           or `MuPDFError.mupdfError`.
    public func deletePages(at indices: [Int]) throws {
        guard !isClosed else { throw MuPDFError.documentClosed }
        let sorted = indices.sorted(by: >)
        for index in sorted {
            guard index >= 0 && index < pageCount else {
                throw MuPDFError.pageIndexOutOfBounds
            }
            // TODO: (requires mupdf submodule)
            //   let ctx = MuPDFContext.shared.ctx
            //   let pdfDoc = pdf_document_from_fz_document(ctx, nativeDoc)
            //   pdf_delete_page(ctx, pdfDoc, Int32(index))
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Close / release
    // -------------------------------------------------------------------------

    /// Releases all native resources held by this document.
    ///
    /// After calling `close()`, most operations will throw
    /// `MuPDFError.documentClosed`. It is safe to call `close()` multiple
    /// times.
    public func close() {
        guard !isClosed else { return }
        isClosed = true
        // TODO: (requires mupdf submodule)
        //   fz_drop_document(MuPDFContext.shared.ctx, nativeDoc)
        nativeDoc = nil
    }

    // -------------------------------------------------------------------------
    // MARK: Private helpers
    // -------------------------------------------------------------------------

    private func metadata(key: String) -> String? {
        // TODO: (requires mupdf submodule)
        //   var buf = [CChar](repeating: 0, count: 256)
        //   fz_lookup_metadata(ctx, nativeDoc, key, &buf, Int32(buf.count))
        //   return String(cString: buf).isEmpty ? nil : String(cString: buf)
        return nil
    }
}
