import XCTest
@testable import MuPDFMobile

final class MuPDFPageTests: XCTestCase {

    // MARK: - Render scale

    func testRenderWithPositiveScaleReturnsBitmap() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        let bitmap = page.render(scale: 1.0)
        // Bitmap dimensions should be non-negative.
        XCTAssertGreaterThanOrEqual(bitmap.width, 0)
        XCTAssertGreaterThanOrEqual(bitmap.height, 0)
        doc.close()
    }

    func testRenderScaleProducesSizedBitmap() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        let scale: Float = 2.0
        let bitmap = page.render(scale: scale)
        // With placeholder dimensions 595 × 842 pt at ×2 scale the bitmap
        // should be 1190 × 1684 px.
        let expectedWidth  = Int(page.width  * scale)
        let expectedHeight = Int(page.height * scale)
        XCTAssertEqual(bitmap.width,  expectedWidth)
        XCTAssertEqual(bitmap.height, expectedHeight)
        doc.close()
    }

    func testRenderPixelDimensions() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        let bitmap = page.render(width: 300, height: 400)
        XCTAssertEqual(bitmap.width,  300)
        XCTAssertEqual(bitmap.height, 400)
        doc.close()
    }

    // MARK: - Tile rendering

    func testRenderTileReturnsTileSizedBitmap() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        let bitmap = page.renderTile(x: 0, y: 0, tileWidth: 256, tileHeight: 256, scale: 1.0)
        XCTAssertEqual(bitmap.width,  256)
        XCTAssertEqual(bitmap.height, 256)
        doc.close()
    }

    func testRenderTileZeroDimensionsReturnsEmpty() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        let bitmap = page.renderTile(x: 0, y: 0, tileWidth: 0, tileHeight: 0, scale: 1.0)
        XCTAssertEqual(bitmap.width,  0)
        XCTAssertEqual(bitmap.height, 0)
        doc.close()
    }

    // MARK: - Annotations

    func testAnnotationsReturnsEmptyArrayInitially() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        XCTAssertTrue(page.annotations().isEmpty)
        doc.close()
    }

    func testAddAnnotationReturnsAnnotationWithMatchingType() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        let rect = MuPDFRect(x: 10, y: 20, width: 100, height: 30)
        let annot = try page.addAnnotation(type: .highlight, rect: rect)
        XCTAssertEqual(annot.type, .highlight)
        XCTAssertEqual(annot.rect.x, rect.x)
        XCTAssertEqual(annot.rect.y, rect.y)
        doc.close()
    }

    // MARK: - Text search

    func testSearchEmptyStringReturnsEmpty() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        XCTAssertTrue(page.search(text: "").isEmpty)
        doc.close()
    }

    // MARK: - Text content

    func testTextContentReturnsStringType() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        // Before submodule: placeholder returns empty string.
        XCTAssertNotNil(page.textContent)
        doc.close()
    }

    // MARK: - Page dimensions

    func testPlaceholderDimensionsArePositive() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        XCTAssertGreaterThan(page.width,  0)
        XCTAssertGreaterThan(page.height, 0)
        doc.close()
    }

    // MARK: - Invalidate

    func testInvalidateIsIdempotent() throws {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        page.invalidate()
        page.invalidate()  // Should not crash.
        doc.close()
    }
}

// MARK: - Internal test helper

extension MuPDFPage {
    /// Convenience init exposed to tests via `@testable import`.
    convenience init(index: Int, document: MuPDFDocument) {
        self.init(index: index, document: document, nativePage: nil)
    }
}
