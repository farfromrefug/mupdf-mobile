import XCTest
@testable import MuPDFMobile

final class MuPDFAnnotationTests: XCTestCase {

    // MARK: - Helpers

    private func makePage() throws -> (MuPDFDocument, MuPDFPage) {
        let doc = try MuPDFDocument.open(data: Data([0x25, 0x50, 0x44, 0x46]))
        let page = MuPDFPage(index: 0, document: doc)
        return (doc, page)
    }

    // MARK: - Type

    func testAnnotationTypeIsPreserved() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let types: [MuPDFAnnotationType] = [
            .highlight, .underline, .strikeout, .squiggly,
            .ink, .square, .circle, .line,
            .text, .stamp, .freeText, .redact, .link
        ]
        for type in types {
            let annot = try page.addAnnotation(type: type, rect: rect)
            XCTAssertEqual(annot.type, type, "Type mismatch for \(type.name)")
        }
        doc.close()
    }

    // MARK: - Rect

    func testAnnotationRectIsPreserved() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 10, y: 20, width: 150, height: 30)
        let annot = try page.addAnnotation(type: .square, rect: rect)
        XCTAssertEqual(annot.rect.x,      rect.x)
        XCTAssertEqual(annot.rect.y,      rect.y)
        XCTAssertEqual(annot.rect.width,  rect.width)
        XCTAssertEqual(annot.rect.height, rect.height)
        doc.close()
    }

    func testAnnotationRectCanBeUpdated() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .highlight, rect: rect)
        let newRect = MuPDFRect(x: 50, y: 60, width: 200, height: 40)
        annot.rect = newRect
        XCTAssertEqual(annot.rect.x, 50)
        XCTAssertEqual(annot.rect.y, 60)
        doc.close()
    }

    // MARK: - Color

    func testAnnotationDefaultColorIsHighlightYellow() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .highlight, rect: rect)
        XCTAssertEqual(annot.color.r, MuPDFColor.highlightYellow.r)
        XCTAssertEqual(annot.color.g, MuPDFColor.highlightYellow.g)
        XCTAssertEqual(annot.color.b, MuPDFColor.highlightYellow.b)
        doc.close()
    }

    func testAnnotationColorCanBeChanged() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .highlight, rect: rect)
        annot.color = MuPDFColor(r: 0, g: 0.5, b: 1, a: 0.8)
        XCTAssertEqual(annot.color.r, 0)
        XCTAssertEqual(annot.color.g, 0.5)
        XCTAssertEqual(annot.color.b, 1)
        doc.close()
    }

    // MARK: - Opacity

    func testAnnotationDefaultOpacityIsOne() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .ink, rect: rect)
        XCTAssertEqual(annot.opacity, 1.0)
        doc.close()
    }

    func testAnnotationOpacityIsClamped() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .ink, rect: rect)
        annot.opacity = 2.0
        XCTAssertEqual(annot.opacity, 1.0, "Opacity should be clamped to 1")
        annot.opacity = -0.5
        XCTAssertEqual(annot.opacity, 0.0, "Opacity should be clamped to 0")
        doc.close()
    }

    // MARK: - Contents

    func testAnnotationContentsRoundTrip() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .text, rect: rect)
        annot.contents = "Review this paragraph."
        XCTAssertEqual(annot.contents, "Review this paragraph.")
        doc.close()
    }

    // MARK: - Update (smoke test — no crash)

    func testUpdateDoesNotCrash() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .highlight, rect: rect)
        annot.color = MuPDFColor(r: 1, g: 0, b: 0, a: 0.5)
        annot.contents = "Changed"
        annot.update()
        // If we reach here without a crash the test passes.
        doc.close()
    }

    // MARK: - Description

    func testDescriptionContainsTypeName() throws {
        let (doc, page) = try makePage()
        let rect = MuPDFRect(x: 0, y: 0, width: 100, height: 20)
        let annot = try page.addAnnotation(type: .stamp, rect: rect)
        XCTAssertTrue(annot.description.contains("Stamp"))
        doc.close()
    }
}
