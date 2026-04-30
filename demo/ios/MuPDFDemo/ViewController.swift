import UIKit
import MuPDFMobile

/// Root view controller — file picker landing screen.
final class ViewController: UIViewController {

    private let pickPdf = UIDocumentPickerViewController(
        forOpeningContentTypes: [.pdf],
        asCopy: true
    )

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis    = .vertical
        sv.spacing = 16
        sv.alignment = .center
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MuPDF Mobile Demo"
        view.backgroundColor = .systemBackground
        pickPdf.delegate = self

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])

        let label = UILabel()
        label.text = "MuPDF Mobile Demo"
        label.font = .systemFont(ofSize: 24, weight: .bold)

        let subtitle = UILabel()
        subtitle.text = "Cross-platform PDF rendering"
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .secondaryLabel

        let openBtn = makeButton(title: "📂  Open PDF", action: #selector(pickDocument))

        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(subtitle)
        stackView.setCustomSpacing(32, after: subtitle)
        stackView.addArrangedSubview(openBtn)
    }

    @objc private func pickDocument() {
        present(pickPdf, animated: true)
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        btn.backgroundColor  = .systemIndigo
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }
}

// MARK: - UIDocumentPickerDelegate

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        openDocument(at: url)
    }

    private func openDocument(at url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let doc = try MuPDFDocument.open(path: url.path)
            let viewer = PDFViewerViewController(document: doc)
            navigationController?.pushViewController(viewer, animated: true)
        } catch {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
