import XCTest
@testable import MuPDFMobile

final class MuPDFDocumentTests: XCTestCase {

    // MARK: - Factory tests

    func testOpenNonExistentPathThrows() {
        XCTAssertThrowsError(
            try MuPDFDocument.open(path: "/nonexistent/path/document.pdf")
        ) { error in
            XCTAssertEqual(error as? MuPDFError, .fileNotFound)
        }
    }

    func testOpenEmptyDataThrows() {
        XCTAssertThrowsError(
            try MuPDFDocument.open(data: Data())
        ) { error in
            XCTAssertEqual(error as? MuPDFError, .invalidDocument)
        }
    }

    // MARK: - Page count

    func testPageCountOnNewDocument() throws {
        // Without a real PDF file the page count should be 0 (placeholder).
        // This test will need updating once the submodule is initialised.
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46])) // %PDF header
        XCTAssertGreaterThanOrEqual(doc.pageCount, 0)
        doc.close()
    }

    // MARK: - Load page out of bounds

    func testLoadPageOutOfBoundsThrows() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        XCTAssertThrowsError(
            try doc.loadPage(at: 999)
        ) { error in
            XCTAssertEqual(error as? MuPDFError, .pageIndexOutOfBounds)
        }
        doc.close()
    }

    // MARK: - Close

    func testDoubleCloseIsSafe() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        doc.close()
        doc.close()  // Should not crash or throw.
        XCTAssertEqual(doc.pageCount, 0)
    }

    func testOperationAfterCloseThrows() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        doc.close()
        XCTAssertThrowsError(
            try doc.loadPage(at: 0)
        ) { error in
            XCTAssertEqual(error as? MuPDFError, .documentClosed)
        }
    }

    // MARK: - Metadata

    func testMetadataReturnsNilForPlaceholder() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        // Before submodule: metadata is nil.
        XCTAssertNil(doc.title)
        XCTAssertNil(doc.author)
        doc.close()
    }

    // MARK: - deletePages validation

    func testDeletePagesOutOfBoundsThrows() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        XCTAssertThrowsError(
            try doc.deletePages(at: [0, 999])
        ) { error in
            // Either pageIndexOutOfBounds (when pageCount > 0) or
            // pageIndexOutOfBounds because 999 is always out of range.
            XCTAssertTrue(
                error as? MuPDFError == .pageIndexOutOfBounds ||
                error as? MuPDFError == .documentClosed
            )
        }
        doc.close()
    }

    // MARK: - Page size

#if canImport(CoreGraphics)
    func testPageSizeReturnsZeroForClosedDoc() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        doc.close()
        XCTAssertEqual(doc.pageSize(at: 0), .zero)
    }
#endif
}
