import Foundation

// MARK: - MuPDFContext

/// Internal singleton that owns the `fz_context` used by all MuPDF operations.
///
/// The context is **not** thread-safe by default. MuPDF supports per-thread
/// clones via `fz_clone_context`; call `clonedContext()` before dispatching
/// work to a background queue.
final class MuPDFContext {

    // -------------------------------------------------------------------------
    // MARK: Singleton
    // -------------------------------------------------------------------------

    /// The shared application-wide context.
    static let shared = MuPDFContext()

    // -------------------------------------------------------------------------
    // MARK: Internal state
    // -------------------------------------------------------------------------

    /// Opaque pointer to the underlying `fz_context`.
    /// Will be non-nil after a successful `setUp()`.
    private(set) var ctx: OpaquePointer?

    private let lock = NSLock()

    // -------------------------------------------------------------------------
    // MARK: Lifecycle
    // -------------------------------------------------------------------------

    private init() {
        setUp()
    }

    deinit {
        tearDown()
    }

    /// Creates the `fz_context`. Called once during initialisation.
    private func setUp() {
        // TODO: (requires mupdf submodule)
        //   ctx = fz_new_context(nil, nil, FZ_STORE_DEFAULT)
        //   guard ctx != nil else { fatalError("Failed to create fz_context") }
        //   fz_register_document_handlers(ctx)
    }

    /// Drops the `fz_context` and releases all associated memory.
    private func tearDown() {
        guard ctx != nil else { return }
        // TODO: fz_drop_context(ctx)
        ctx = nil
    }

    // -------------------------------------------------------------------------
    // MARK: Thread support
    // -------------------------------------------------------------------------

    /// Returns a clone of the context suitable for use on a different thread.
    ///
    /// The caller is responsible for dropping the cloned context when done.
    func clonedContext() -> OpaquePointer? {
        // TODO: return fz_clone_context(ctx)
        return nil
    }

    // -------------------------------------------------------------------------
    // MARK: Locking
    // -------------------------------------------------------------------------

    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
