import Foundation

/// A single entry in a PDF's table of contents (outline).
#if canImport(ObjectiveC)
@objcMembers
#endif
public final class MuPDFOutlineItem: NSObject {
    /// The display title of this outline entry.
    public let title: String
    /// Zero-based page index this entry links to, or -1 if not a page link.
    public let pageIndex: Int
    /// Child entries nested beneath this entry.
    public let children: [MuPDFOutlineItem]

    public init(title: String, pageIndex: Int, children: [MuPDFOutlineItem] = []) {
        self.title = title
        self.pageIndex = pageIndex
        self.children = children
    }

    public override var description: String {
        "MuPDFOutlineItem(title: \"\(title)\", page: \(pageIndex), children: \(children.count))"
    }
}
