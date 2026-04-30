import Foundation
import CoreGraphics

// MARK: - C ↔ Swift type helpers

/// Converts a `MuPDFRect` to the MuPDF C `fz_rect` layout (4 floats).
/// Returns a tuple `(x0, y0, x1, y1)` matching `fz_rect`.
func toFzRect(_ rect: MuPDFRect) -> (Float, Float, Float, Float) {
    return (rect.x, rect.y, rect.x + rect.width, rect.y + rect.height)
}

/// Converts `fz_rect` components back to a `MuPDFRect`.
func fromFzRect(x0: Float, y0: Float, x1: Float, y1: Float) -> MuPDFRect {
    MuPDFRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
}

/// Converts a `MuPDFColor` to a float array suitable for `fz_set_color`.
func toFzColor(_ color: MuPDFColor) -> [Float] {
    return [color.r, color.g, color.b]
}

// MARK: - Error bridging

/// Executes a throwing block and maps any `MuPDFError` to an NSError for
/// Objective-C callers who receive an `NSError **` parameter.
func bridgedThrow<T>(
    _ block: () throws -> T,
    error outError: UnsafeMutablePointer<NSError?>?
) -> T? {
    do {
        return try block()
    } catch let e as MuPDFError {
        outError?.pointee = e as NSError
        return nil
    } catch {
        outError?.pointee = error as NSError
        return nil
    }
}

// MARK: - Annotation type ↔ MuPDF int mapping

/// Maps a `MuPDFAnnotationType` to the corresponding `PDF_ANNOT_*` integer
/// constant used by the MuPDF C API.
func annotationTypeToMuPDF(_ type: MuPDFAnnotationType) -> Int32 {
    switch type {
    // Values mirror PDF_ANNOT_* constants from pdf-annot.h
    case .text:        return 0
    case .link:        return 1
    case .freeText:    return 2
    case .line:        return 3
    case .square:      return 4
    case .circle:      return 5
    case .ink:         return 14
    case .highlight:   return 15
    case .underline:   return 16
    case .squiggly:    return 17
    case .strikeout:   return 18
    case .stamp:       return 20
    case .redact:      return 24
    case .link:        return 1
    }
}

/// Maps a MuPDF `PDF_ANNOT_*` integer back to a `MuPDFAnnotationType`.
func annotationTypeFromMuPDF(_ raw: Int32) -> MuPDFAnnotationType {
    switch raw {
    case 0:  return .text
    case 1:  return .link
    case 2:  return .freeText
    case 3:  return .line
    case 4:  return .square
    case 5:  return .circle
    case 14: return .ink
    case 15: return .highlight
    case 16: return .underline
    case 17: return .squiggly
    case 18: return .strikeout
    case 20: return .stamp
    case 24: return .redact
    default: return .text
    }
}

// MARK: - CGSize helper

extension CGSize {
    init(width: Float, height: Float) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}
