import UIKit
import MuPDFMobile

/// A simple single-page PDF viewer backed by `MuPDFDocument`.
///
/// Displays one page at a time with a scroll view for pan/zoom and
/// a page-number toolbar at the bottom.
final class PDFViewerViewController: UIViewController {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Dependencies
    // ─────────────────────────────────────────────────────────────────────────

    private let document: MuPDFDocument
    private var currentPageIndex: Int = 0

    init(document: MuPDFDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: UI
    // ─────────────────────────────────────────────────────────────────────────

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 0.5
        sv.maximumZoomScale = 4.0
        sv.delegate = self
        sv.backgroundColor = .systemGroupedBackground
        return sv
    }()

    private lazy var pageImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.layer.shadowColor  = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.25
        iv.layer.shadowRadius  = 8
        iv.layer.shadowOffset  = .zero
        return iv
    }()

    private lazy var toolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()

    private lazy var pageLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        return lbl
    }()

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        title = document.title ?? "PDF Viewer"
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(pageImageView)
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            pageImageView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            pageImageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            pageImageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            pageImageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            pageImageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        setupToolbar()
        renderCurrentPage()
    }

    deinit {
        document.close()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func setupToolbar() {
        let prevBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(previousPage)
        )
        let nextBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(nextPage)
        )
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let pageLabelItem = UIBarButtonItem(customView: pageLabel)

        toolbar.items = [prevBtn, spacer, pageLabelItem, spacer, nextBtn]
        updatePageLabel()
    }

    private func renderCurrentPage() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let page   = try self.document.loadPage(at: self.currentPageIndex)
                let scale  = Float(UIScreen.main.scale)
                let bitmap = page.render(scale: scale)
                DispatchQueue.main.async {
                    self.pageImageView.image = bitmap.image
                    self.updatePageLabel()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.pageImageView.image = nil
                }
            }
        }
    }

    private func updatePageLabel() {
        pageLabel.text = "\(currentPageIndex + 1) / \(document.pageCount)"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Actions
    // ─────────────────────────────────────────────────────────────────────────

    @objc private func previousPage() {
        guard currentPageIndex > 0 else { return }
        currentPageIndex -= 1
        renderCurrentPage()
    }

    @objc private func nextPage() {
        guard currentPageIndex < document.pageCount - 1 else { return }
        currentPageIndex += 1
        renderCurrentPage()
    }
}

// MARK: - UIScrollViewDelegate

extension PDFViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        pageImageView
    }
}
