import Foundation
import CoreGraphics

// MARK: - MuPDFRect

/// A rectangle in PDF user-space coordinates (origin at bottom-left for PDF,
/// but presented here in screen-space with origin at top-left for convenience).
@objc public final class MuPDFRect: NSObject, NSCopying {
    /// X coordinate of the top-left corner, in points.
    @objc public var x: Float
    /// Y coordinate of the top-left corner, in points.
    @objc public var y: Float
    /// Width of the rectangle, in points.
    @objc public var width: Float
    /// Height of the rectangle, in points.
    @objc public var height: Float

    /// Creates a new `MuPDFRect`.
    @objc public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Convenience initialiser from a `CGRect`.
    public convenience init(_ rect: CGRect) {
        self.init(
            x: Float(rect.origin.x),
            y: Float(rect.origin.y),
            width: Float(rect.width),
            height: Float(rect.height)
        )
    }

    /// Returns a `CGRect` equivalent for use with UIKit / AppKit.
    public var cgRect: CGRect {
        CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MuPDFRect(x: x, y: y, width: width, height: height)
    }

    public override var description: String {
        "MuPDFRect(x: \(x), y: \(y), width: \(width), height: \(height))"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MuPDFRect else { return false }
        return x == other.x && y == other.y && width == other.width && height == other.height
    }
}

// MARK: - MuPDFColor

/// An RGBA colour value. All components are in the range [0, 1].
@objc public final class MuPDFColor: NSObject, NSCopying {
    /// Red component in [0, 1].
    @objc public var r: Float
    /// Green component in [0, 1].
    @objc public var g: Float
    /// Blue component in [0, 1].
    @objc public var b: Float
    /// Alpha component in [0, 1]. 1 = fully opaque.
    @objc public var a: Float

    /// Creates a new `MuPDFColor`.
    @objc public init(r: Float, g: Float, b: Float, a: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// Opaque black.
    @objc public static let black = MuPDFColor(r: 0, g: 0, b: 0, a: 1)
    /// Opaque white.
    @objc public static let white = MuPDFColor(r: 1, g: 1, b: 1, a: 1)
    /// Semi-transparent yellow (useful as a highlight colour).
    @objc public static let highlightYellow = MuPDFColor(r: 1, g: 1, b: 0, a: 0.5)
    /// Semi-transparent red.
    @objc public static let highlightRed = MuPDFColor(r: 1, g: 0, b: 0, a: 0.5)

    public func copy(with zone: NSZone? = nil) -> Any {
        MuPDFColor(r: r, g: g, b: b, a: a)
    }

    public override var description: String {
        "MuPDFColor(r: \(r), g: \(g), b: \(b), a: \(a))"
    }
}

// MARK: - MuPDFAnnotationType

/// The type of a PDF annotation.
@objc public enum MuPDFAnnotationType: Int {
    /// Yellow highlight over text.
    case highlight = 0
    /// Underline beneath text.
    case underline
    /// Strikethrough over text.
    case strikeout
    /// Squiggly underline.
    case squiggly
    /// Free-hand ink drawing.
    case ink
    /// Rectangle / box shape.
    case square
    /// Ellipse / circle shape.
    case circle
    /// Straight line.
    case line
    /// Sticky-note (text comment).
    case text
    /// Stamp annotation (e.g. "APPROVED").
    case stamp
    /// Free-text annotation drawn directly on the page.
    case freeText
    /// Redaction mark (content hidden after `applyRedactions()`).
    case redact
    /// Hyperlink annotation.
    case link

    /// Human-readable name of the annotation type.
    public var name: String {
        switch self {
        case .highlight: return "Highlight"
        case .underline: return "Underline"
        case .strikeout: return "StrikeOut"
        case .squiggly: return "Squiggly"
        case .ink: return "Ink"
        case .square: return "Square"
        case .circle: return "Circle"
        case .line: return "Line"
        case .text: return "Text"
        case .stamp: return "Stamp"
        case .freeText: return "FreeText"
        case .redact: return "Redact"
        case .link: return "Link"
        }
    }
}

// MARK: - MuPDFError

/// Errors thrown by the MuPDF Mobile library.
@objc public enum MuPDFError: Int, Error {
    /// The specified file path could not be opened.
    case fileNotFound = 1
    /// The data provided is not a valid PDF.
    case invalidDocument
    /// The requested page index is out of bounds.
    case pageIndexOutOfBounds
    /// The annotation could not be created.
    case annotationCreationFailed
    /// A save or write operation failed.
    case saveFailed
    /// The underlying MuPDF context could not be created.
    case contextCreationFailed
    /// A generic error from the underlying MuPDF C layer.
    case mupdfError
    /// An operation was attempted on a closed document.
    case documentClosed
}

extension MuPDFError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileNotFound: return "The file could not be found or opened."
        case .invalidDocument: return "The data does not represent a valid PDF document."
        case .pageIndexOutOfBounds: return "The page index is out of bounds."
        case .annotationCreationFailed: return "Failed to create the annotation."
        case .saveFailed: return "Failed to save the document."
        case .contextCreationFailed: return "Failed to create the MuPDF context."
        case .mupdfError: return "An internal MuPDF error occurred."
        case .documentClosed: return "The document has already been closed."
        }
    }
}
