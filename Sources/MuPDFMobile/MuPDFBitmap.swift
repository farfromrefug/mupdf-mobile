import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import CoreGraphics

// MARK: - MuPDFBitmap

/// A platform-native bitmap produced by rendering a ``MuPDFPage``.
///
/// - On iOS / tvOS / watchOS the underlying image is exposed as a `UIImage`
///   via the ``image`` property.
/// - On macOS the underlying image is exposed as an `NSImage` via
///   ``nsImage``.
@objc public final class MuPDFBitmap: NSObject {

    // -------------------------------------------------------------------------
    // MARK: Properties
    // -------------------------------------------------------------------------

    /// Width of the bitmap in pixels.
    @objc public let width: Int

    /// Height of the bitmap in pixels.
    @objc public let height: Int

    /// Raw RGBA pixel data (4 bytes per pixel, row-major).
    @objc public private(set) var pixelData: Data?

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    /// Creates an empty bitmap with the given pixel dimensions.
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixelData = nil
    }

    /// Creates a bitmap from raw RGBA pixel data.
    ///
    /// - Parameters:
    ///   - width:     Bitmap width in pixels.
    ///   - height:    Bitmap height in pixels.
    ///   - pixelData: Raw RGBA bytes (must be `width * height * 4` bytes).
    init(width: Int, height: Int, pixelData: Data) {
        self.width = width
        self.height = height
        self.pixelData = pixelData
    }

    // -------------------------------------------------------------------------
    // MARK: Platform image accessors
    // -------------------------------------------------------------------------

#if canImport(UIKit)
    /// The rendered page as a `UIImage`. Returns `nil` for empty bitmaps.
    @objc public var image: UIImage? {
        guard let data = pixelData, width > 0, height > 0 else { return nil }
        return data.withUnsafeBytes { ptr -> UIImage? in
            guard let base = ptr.baseAddress else { return nil }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let provider = CGDataProvider(data: data as CFData),
                  let cgImage = CGImage(
                      width: width, height: height,
                      bitsPerComponent: 8, bitsPerPixel: 32,
                      bytesPerRow: width * 4,
                      space: colorSpace,
                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                      provider: provider,
                      decode: nil,
                      shouldInterpolate: true,
                      intent: .defaultIntent
                  ) else { return nil }
            _ = base  // suppress unused warning
            return UIImage(cgImage: cgImage)
        }
    }
#endif

#if canImport(AppKit) && !canImport(UIKit)
    /// The rendered page as an `NSImage`. Returns `nil` for empty bitmaps.
    public var nsImage: NSImage? {
        guard let data = pixelData, width > 0, height > 0 else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(
                  width: width, height: height,
                  bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: width * 4,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              ) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
#endif

    // -------------------------------------------------------------------------
    // MARK: Description
    // -------------------------------------------------------------------------

    public override var description: String {
        "MuPDFBitmap(\(width)×\(height))"
    }
}
